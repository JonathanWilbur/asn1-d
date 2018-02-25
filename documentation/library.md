# Usage

## Terminology

* This library uses the term "element" to refer to a datum encoded using one of the ASN.1 codecs.
* This library uses the term "mantissa" instead of "significand," because "mantissa" is what's used in the specification.

## Floating Point

This library expects that the target system uses IEEE 754 floating-point formats.

## Structure

This library begins with `source/asn1/codec.d`, whose flagship item is `ASN1Element`,
the abstract class from which all other codecs must inherit. An `ASN1Element`
represents a single encoded value (although it could be a single `SEQUENCE`
or `SET`). In the `source/asn1/codecs` directory, you will find all of the codecs that
inherit from `ASN1Element`. The `BERElement` class, for instance, can be found in
`ber.d`, and it represents a ASN.1 value, encoded via the Basic Encoding Rules
(BER) specified in the
[International Telecommunications Union](https://www.itu.int/en/pages/default.aspx)'s
[X.690 - ASN.1 encoding rules](https://www.itu.int/rec/T-REC-X.690/en).

The codecs rely upon a few ASN.1-specific data types, such as `EmbeddedPDV`,
and these data types have their own classes or structs somewhere in the
`source/asn1/types` directory. In `source/asn1/types`, you will find `alltypes.d`,
which just provides a convenient way to import all data types instead of having
multiple import statements for each. There, you will also find data types
that are used by other data types. In `source/asn1/types/universal`, you will
find D data types for some of ASN.1's universal data types. You will also notice
the directory `source/asn1/tools`. This directory is for the command-line tools.

## Usage

For each codec in the library, usage entails instantiating the class,
then using that class' properties to get and set the encoded value.
For all classes, the empty constructor creates an `END OF CONTENT`
element. The remaining constructors will be codec-specific.

Here is an example of encoding with Basic Encoding Rules, using the
`BERElement` class.

```d
BERElement el = new BERElement();
el.typeTag = ASN1UniversalType.integer;
el.integer!long = 1433; // Now the data is encoded.
writefln("%(%02X %)", cast(ubyte[]) el); // Writes the encoded bytes to the terminal.
```

... and here is how you would decode that same element:

```d
ubyte[] encodedData = cast(ubyte[]) el;
BERElement el2 = new BERElement(encodedData);
long x = el2.integer!long;
```

If you know that the encoding bytes contain only one element, you can also
decode an array of `ubyte`s by value instead of by reference, like so:

```d
BERElement el3 = new BERElement(el.toBytes);
assert(el.integer!long == el3.integer!long); // Passes
```

Each codec contains accessors and mutators for each ASN.1 data type. Each property
takes or returns the data type you would expect it to return (for instance, the
`integer` property returns a signed integral type), and each property is given
the unabbreviated name of the data type it encodes, with aliases mapping the
abbreviated names to the unabbreviated names. There are a few exceptions:

* There are no `endOfContent` or `null` mutators.
* The accessors for `endOfContent` and `nill` (that's not a typo), do not return a value; they just throw an exception if the encoded value is not a well-formed `END OF CONTENT` or `NULL`, respectively.
* The properties for getting and setting a `REAL` are named `realNumber`, because `real` is a keyword in D.

Taken from `source/asn1/codec.d`, the members that each codec has are as
follows:

```d
    public ASN1TagClass tagClass;
    public ASN1Construction construction;
    public size_t tagNumber;

    public @property @safe nothrow
    size_t length() const;

    public ubyte[] value;

    public @system
    void validateTag
    (
        ASN1TagClass[] acceptableTagClasses,
        ASN1Construction acceptableConstruction,
        size_t[] acceptableTagNumbers,
        string whatYouAttemptedToDo
    ) const;

    public @system
    void validateTag
    (
        ASN1TagClass[] acceptableTagClasses,
        size_t[] acceptableTagNumbers,
        string whatYouAttemptedToDo
    ) const;

    public @property @safe @nogc nothrow
    bool isUniversal() const;

    public @property @safe @nogc nothrow
    bool isApplication() const;

    public @property @safe @nogc nothrow
    bool isContextSpecific() const;

    public @property @safe @nogc nothrow
    bool isPrivate() const;

    public @property @safe @nogc nothrow
    bool isPrimitive() const;

    public @property @safe @nogc nothrow
    bool isConstructed() const;

    abstract public @property
    void endOfContent() const;

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

    abstract public @property
    void nill() const;

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

And though it is not implemented on `ASN1Element` (because I cannot confirm
that these are universal properties of all ASN.1 codecs), all of the X.690
codecs (BER, CER, and DER) contain these members:

```d

```

The relevant `enum`s can be found in `source/asn1.d`, and are as follows:

```d
public alias ASN1TagClass = AbstractSyntaxNotation1TagClass;
immutable public
enum AbstractSyntaxNotation1TagClass : ubyte
{
    universal = 0b00000000u, // Native to ASN.1
    application = 0b01000000u, // Only valid for one specific application
    contextSpecific = 0b10000000u, // Specific to a sequence, set, or choice
    privatelyDefined = 0b11000000u // Defined in private specifications
}

public alias ASN1Construction = AbstractSyntaxNotation1Construction;
immutable public
enum AbstractSyntaxNotation1Construction : ubyte
{
    primitive = 0b00000000u, // The content octets directly encode the element value
    constructed = 0b00100000u // The content octets contain 0, 1, or more element encodings
}
```

### Encoding Selected Types

#### `END OF CONTENT`

Just calling the default constructor produces an `END OF CONTENT` element. For
example:

```d
BERElement ber = new BERElement();
assert(ber.toBytes == [ 0x00u, 0x00u ]); // Passes
```

However, you should not need to do this. When you encode data in indefinite-
length form, the codec should append the `END OF CONTENT` octets for you.

If for some reason, you do need to decode an `END OF CONTENT` yourself,
consider using the method `endOfContent`, which returns nothing, but
throws an exception if something is wrong with the tag or length encoding.
For example:

```d
BERElement ber = new BERElement();
assertNotThrown!ASN1Exception(ber.endOfContent);

ber.value = [ 0x01u ];
assertThrown!ASN1Exception(ber.endOfContent);
ber.value = [];

ber.construction = ASN1Construction.constructed;
assertThrown!ASN1Exception(ber.endOfContent);
```

#### `NULL`

This is the same as `END OF CONTENT`, described above, but instead, the method
is named `nill`. It is named `nill` and not `null`, because `null` is a keyword
in D.

#### `ANY`

You just encode any data type like normal, then cast the element to a `ubyte[]`.
The returned value can be inserted where `ANY` goes.

#### `CHOICE`

Mind [CVE-2011-1142](https://nvd.nist.gov/vuln/detail/CVE-2011-1142).

You just encode any data type like normal, then cast the element to a `ubyte[]`.
The returned value can be inserted where `CHOICE` goes.

#### `INSTANCE OF`

This is encoded the same way that an `EXTERNAL` is encoded, but you must use
the `direct-reference` / `syntax` for `identification`.

#### `SET OF`

This is encoded the same way that `SET` is encoded.

#### `SEQUENCE OF`

This is encoded the same way that `SEQUENCE` is encoded.

### Error Handling

This is the exception hierarchy:

- `ASN1Exception`
  - `ASN1CodecException`
    - `ASN1RecursionException`
    - `ASN1TruncationException`
    - `ASN1TagException`
      - `ASN1TagOverflowException`
      - `ASN1TagPaddingException`
      - `ASN1TagNumberException`
    - `ASN1LengthException`
      - `ASN1LengthOverflowException`
      - `ASN1LengthUndefinedException`
    - `ASN1ValueException`
      - `ASN1ValueSizeException`
      - `ASN1ValueOverflowException`
      - `ASN1ValuePaddingException`
      - `ASN1ValueCharactersException`
      - `ASN1ValueUndefinedException`
  - `ASN1CompilerException`

The names are pretty self-explanatory (at least I think so). To learn the
usage of each one, consult the generated HTML documentation in
`documentation/html`.

## Security Tips

* Always use recursion counts to break infinite recusion. See CVE-2016-4421's description in `documentation/security.md`.
  * This is especially true for when you recursively parse constructed elements. See CVE-2010-3445's description in `documentation/security.md`.
    * This is *mega* true for when you recursively parse indefinite-length constructed elements. See CVE-2010-2284's description in `documentation/security.md`.
* Ensure that iteration over `CHOICE` elements cannot loop forever. See CVE-2017-9023's description in `documentation/security.md`.
* Whenever you do arithmetic with externally-supplied data, look carefully for values that are susceptible to buffer underflows, such as `T.min` and `T.max`, where `T` is any integral type.