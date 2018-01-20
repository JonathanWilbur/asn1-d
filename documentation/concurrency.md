# Concurrent Programming with this Library

## Problems with Concurrency

### Encoding

Though data can be encoded in parallel easily, they are often encoded with the
intention of being concatenated into a single buffer for delivery to another
host. You may use the normal patterns of concurrency to encode data in
parallel, but be wary of potential race conditions introduced by inserting
encoded data into a shared buffer prior to delivery.

### Decoding

Decoding is where the real concurrency nightmare begins. The data to be decoded
starts off as an array of unsigned bytes. The elements are encoded in order,
and must be decoded in that order. The second element cannot be decoded before
the first element is decoded, because decoding the first element is necessary
for determining where the second element begins (in other words, which byte
marks the beginning of the second element). For this reason, the concurrency of
this codec is fundamentally limited by this fact.

However, the decoding process, when using this library, is more like a two-step
process. The steps are as follows:

1. You decode the array of unsigned bytes into an array of elements, which
essentially just parses the tag class, construction, tag number, and length of
the element, then "snips" the bytes that belong to that element from the array
and stores it in an internal buffer owned by the element. You do this
iteratively until there are no more bytes to be decoded.
2. When the accessors for the respective data types are called for each
element, the array of unsigned bytes that are internal to each element
are then further decoded to return the type indicated by the chosen accessor.

Though I have not tried this, I believe this library can be concurrent with
two threads, one performing the first step, and another performing the second.
In other words, the first thread converts `ubyte[]` to `BERElement[]` and the
second thread takes the `BERElement[]` and does whatever it needs to do with
each element.

### Warnings

You should not attempt to multithread manipulating the internal buffer of an
element. The individual elements are not thread-safe. This opens any code up
to TOCTOU vulnerabilities.

Let's take a theoretical multi-threaded `BOOLEAN` decoding, for instance:

This is the actual code for the `boolean` accessor from `source/asn1/codecs/der.d`:

```d
    override public @property @safe
    bool boolean() const
    {
        if (this.value.length != 1u)
            throw new ASN1ValueSizeException
            (
                "In Distinguished Encoding Rules (DER), a BOOLEAN must be encoded on exactly " ~
                "one byte (in addition to the type and length bytes, of " ~
                "course). This exception was thrown because you attempted to " ~
                "decode a BOOLEAN from an element that had either zero or more " ~
                "than one bytes as the encoded value. " ~ notWhatYouMeantText ~
                forMoreInformationText ~ debugInformationText ~ reportBugsText
            );

        if (this.value[0] == 0xFFu)
        {
            return true;
        }
        else if (this.value[0] == 0x00u)
        {
            return false;
        }
        else
        {
            throw new ASN1ValueException
            (
                "This exception was thrown because you attempted to decode a BOOLEAN " ~
                "that was encoded on a byte that was not 0xFF or 0x00 using the DER " ~
                "codec. Any encoding of a boolean other than 0xFF (true) or 0x00 " ~
                "(false) is restricted by the DER codec. " ~ notWhatYouMeantText ~
                forMoreInformationText ~ debugInformationText ~ reportBugsText
            );
        }
    }
```

The first line of this accessor checks that the value is exactly one byte.
If this condition is satisfied initially, then a second thread intervenes and
empties the element's internal buffer, then the execution of the subsequent
line of code will induce an out-of-bounds read, because `this.value` (which
is the internal buffer, in this case) will not have a byte with an index of [0]
(nor any bytes at all, for that matter).

## Future Developments

I am considering the possibility of creating thread-local duplicates of the
internal buffers of each element within the bodies of the accessors, so that
the data on which the decoding will be performed will be private to the thread,
but the overhead of duplicating arrays could be disastrous--especially if large
arrays are in question.

Also, the `synchronized` keyword in D may be of interest. I may explore making
parts of this library `synchronized`, but that will involve a lot of very
complicated testing to ensure that it is really safe.