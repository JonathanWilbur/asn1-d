# Contributing

This page describes how to add your own codec to this library.

## How to design your code

All codecs are really just "Elements," and they all should inherit from
`ASN1Element` and `Byteable`, which can be found in `source/asn1/codec.d` and
`source/asn1/interfaces.d` respectively.

Let's say that you had your own set of ASN.1 encoding rules called
"Thicc Encoding Rules" (TER). You would create a class whose signature is
as follows:

```d
///
public alias TERElement = ThiccEncodingRulesElement;
///
public
class ThiccEncodingRulesElement : ASN1Element!TERElement, Byteable
{
    ...
}
```

Then, the restrictions imposed by the compiler should guide you from there.
You will need to implement all of these methods from `ASN1Element`:

```d
    abstract public @property
    bool boolean() const;

    abstract public @property
    void boolean(in bool value);

    abstract public @property
    T integer(T)() const if (isIntegral!T && isSigned!T);

    abstract public @property
    void integer(T)(in T value) if (isIntegral!T && isSigned!T);

    abstract public @property
    bool[] bitString() const;

    abstract public @property
    void bitString(in bool[] value);

    abstract public @property
    ubyte[] octetString() const;

    abstract public @property
    void octetString(in ubyte[] value);

    public alias oid = objectIdentifier;
    public alias objectID = objectIdentifier;
    abstract public @property
    OID objectIdentifier() const;

    abstract public @property
    void objectIdentifier(in OID value);

    abstract public @property
    string objectDescriptor() const;

    abstract public @property
    void objectDescriptor(in string value);

    deprecated abstract public @property
    External external() const;

    deprecated abstract public @property
    void external(in External value);

    abstract public @property
    T realNumber(T)() const if (isFloatingPoint!T);

    abstract public @property
    void realNumber(T)(in T value) if (isFloatingPoint!T);

    abstract public @property
    T enumerated(T)() const if (isIntegral!T && isSigned!T);

    abstract public @property
    void enumerated(T)(in T value) if (isIntegral!T && isSigned!T);

    abstract public @property
    EmbeddedPDV embeddedPresentationDataValue() const;

    abstract public @property
    void embeddedPresentationDataValue(in EmbeddedPDV value);

    public alias utf8String = unicodeTransformationFormat8String;
    abstract public @property
    string unicodeTransformationFormat8String() const;

    abstract public @property
    void unicodeTransformationFormat8String(in string value);

    public alias roid = relativeObjectIdentifier;
    public alias relativeOID = relativeObjectIdentifier;
    abstract public @property
    OIDNode[] relativeObjectIdentifier() const;

    abstract public @property
    void relativeObjectIdentifier(in OIDNode[] value);

    abstract public @property
    Element[] sequence() const;

    abstract public @property
    void sequence(in Element[] value);

    abstract public @property
    Element[] set() const;

    abstract public @property
    void set(in Element[] value);

    abstract public @property
    string numericString() const;

    abstract public @property
    void numericString(in string value);

    abstract public @property
    string printableString() const;

    abstract public @property
    void printableString(in string value);

    public alias t61String = teletexString;
    abstract public @property
    ubyte[] teletexString() const;

    abstract public @property
    void teletexString(in ubyte[] value);

    abstract public @property
    ubyte[] videotexString() const;

    abstract public @property
    void videotexString(in ubyte[] value);

    public alias ia5String = internationalAlphabetNumber5String;
    abstract public @property
    string internationalAlphabetNumber5String() const;

    abstract public @property
    void internationalAlphabetNumber5String(in string value);

    public alias utc = coordinatedUniversalTime;
    public alias utcTime = coordinatedUniversalTime;
    abstract public @property
    DateTime coordinatedUniversalTime() const;

    abstract public @property
    void coordinatedUniversalTime(in DateTime value);

    abstract public @property
    DateTime generalizedTime() const;

    abstract public @property
    void generalizedTime(in DateTime value);

    deprecated
    abstract public @property
    string graphicString() const;

    deprecated
    abstract public @property
    void graphicString(in string value);

    public alias iso646String = visibleString;
    abstract public @property
    string visibleString() const;

    abstract public @property
    void visibleString(in string value);

    deprecated
    abstract public @property
    string generalString();

    deprecated
    abstract public @property
    void generalString(in string value);

    abstract public @property
    dstring universalString() const;

    abstract public @property
    void universalString(in dstring value);

    abstract public @property
    CharacterString characterString() const;

    abstract public @property
    void characterString(in CharacterString value);

    public alias bmpString = basicMultilingualPlaneString;
    abstract public @property
    wstring basicMultilingualPlaneString() const;

    abstract public @property
    void basicMultilingualPlaneString(in wstring value);
```

Then, on top of that, you need to define constructors for your codec, but those
are not constrained by the parent class, so it is up to you how you want to
implement those.

Also, this should be the first section of code in the class you create:

```d
    @system
    unittest
    {
        writeln("Running unit tests for codec: " ~ typeof(this).stringof);
    }
```

Which leads me to my next point...

## Testing

It should go without saying that everything should be tested meticulously.
You should not just assume that remote clients will always send valid data.
I expect additional unit tests to be written for each accessor with
invalid data as inputs to ensure that nothing can induce out-of-bounds reads.

Further, at the end of all of this, you should modify all of the files in
`test/fuzz` and recompile them to test your new codec. Running all 4.2 billion
fuzz tests will take several hours, even on a beefy computer, but it's worth it.
If you see a `RangeError` thrown, it means you screwed something up and your
code is not acceptable for inclusion in this library.

## Code Quality

Every member of your codec should have the appropriate attributes. Every one
should either be marked as `@system`, `@safe`, or `@trusted`. I will probably
not accept your code into this library if you mark anything as `@trusted`. I
don't even trust my code enough to mark it as `@trusted`.

## Submission

Everything takes place on GitHub. Just submit a pull request. I'll review it
and pull it.

## Last Note

If you've made it this far into this document, I would like to thank you ahead
of time for the contribution you have considered making. If you contribute
significantly, I will put your name (or merge your pull request that puts your
name) in `documentation/credits.csv`.