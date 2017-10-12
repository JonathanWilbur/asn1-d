module codec;
import asn1;
import types.alltypes;
// import types.universal.objectidentifier;
import std.bitmanip : BitArray;
import std.traits : isIntegral;

class ASN1CodecException : ASN1Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

// An abstract class from which both ASN1BinaryCodec and ASN1TextCodec will inherit.
abstract public
class ASN1Value
{

}

// REVIEW: Should the setters return booleans indicating success instead of throwing errors?
abstract public
class ASN1BinaryValue : ASN1Value
{
    protected import std.datetime.date : DateTime;
    private import std.math : log2;

    alias LLEP = LongLengthEncodingPreference;
    public
    enum LongLengthEncodingPreference
    {
        definite,
        indefinite
    }

    // Constants used to save CPU cycles
    private immutable real maxUintAsReal = cast(real) uint.max; // Saves CPU cycles in encodeReal()
    private immutable real maxUlongAsReal = cast(real) ulong.max; // Saves CPU cycles in encodeReal()
    private immutable real logBaseTwoOfTen = log2(10.0); // Saves CPU cycles in encodeReal()

    // Settings
    static public LLEP longLengthEncodingPreference = LLEP.definite;
    static public bool encodeEverythingExplicitly = false;
    static public bool base10RealShouldShowPlusSignIfPositive = false;
    static public Base10RealDecimalSeparator base10RealDecimalSeparator = Base10RealDecimalSeparator.period;
    static public Base10RealExponentCharacter base10RealExponentCharacter = Base10RealExponentCharacter.uppercaseE;
    static public Base10RealNumericalRepresentation base10RealNumericalRepresentation = Base10RealNumericalRepresentation.nr3;
    static public RealEncodingBase _realEncodingBase = RealEncodingBase.base2;
    static public RealBinaryEncodingBase _realBinaryEncodingBase = RealBinaryEncodingBase.base2;
    // TODO: maximumValueLength (to prevent DoS attacks)

    // public ASN1TypeTag type;
    public ubyte type;

    public @property
    bool universal()
    {
        return ((this.type & 0xC) == 0x00);
    }

    public @property
    bool applicationSpecific()
    {
        return ((this.type & 0xC) == 0x40);
    }

    public @property
    bool contextSpecific()
    {
        return ((this.type & 0xC) == 0x80);
    }

    public @property
    bool privatelySpecific()
    {
        return ((this.type & 0xC) == 0x40);
    }

    public @property
    size_t length()
    {
        return this.value.length;
    }

    public ubyte[] value;

    // Convenience
    // pragma(inline, true);
    private
    void throwIfEmptyValue(X : ASN1CodecException)()
    {
        if (this.length != 1) throw new X ("Value bytes was zero");
    }

    public
    ubyte[] opCast(T = ubyte[])()
    {
        return [];
    }

    // END OF CONTENT
    // IDEA: Make the empty constructor for each ER create an EOC.
    // abstract public @property 
    // endOfContent();

    // abstract public @property
    // void endOfContent(void* value); // REVIEW

    // BOOLEAN
    abstract public @property
    bool boolean();

    abstract public @property
    void boolean(bool value);

    // INTEGER
    // TODO: Make this support more types.
    abstract public @property
    long integer();

    abstract public @property
    void integer(long value);

    // BIT STRING
    abstract public @property
    BitArray bitString();

    abstract public @property
    void bitString(BitArray value);

    // OCTET STRING
    abstract public @property
    ubyte[] octetString();

    abstract public @property
    void octetString(ubyte[] value);

    // NULL
    abstract public @property
    ubyte[] nill();

    abstract public @property
    void nill(ubyte[] value); // REVIEW?

    // OBJECT IDENTIFIER
    abstract public @property
    OID objectIdentifier();

    abstract public @property
    void objectIdentifier(OID value);

    // ObjectDescriptor
    abstract public @property
    string objectDescriptor();

    abstract public @property
    void objectDescriptor(string value);

    // EXTERNAL
    abstract public @property
    External external();

    abstract public @property
    void external(External value);

    // REAL
    // TODO: Make string variants
    abstract public @property
    T realType(T)() if (is(T == float) || is(T == double));

    abstract public @property
    void realType(T)(T value) if (is(T == float) || is(T == double));

    // ENUMERATED
    abstract public @property
    long enumerated();

    abstract public @property
    void enumerated(long value);

    // EMBEDDED PDV
    abstract public @property
    EmbeddedPDV embeddedPDV();

    abstract public @property
    void embeddedPDV(EmbeddedPDV value);

    // UTF8String
    abstract public @property
    string utf8string();

    abstract public @property
    void utf8string(string value);

    // RELATIVE OID
    abstract public @property
    RelativeOID relativeObjectIdentifier();

    abstract public @property
    void relativeObjectIdentifier(RelativeOID value);

    // SEQUENCE
    // abstract public @property
    // BERValue[] sequence();

    // abstract public @property
    // void sequence(BERValue[] value);

    // SET
    // abstract public @property
    // BERValue[] set();

    // abstract public @property
    // void set(BERValue[] value);

    // NumericString
    abstract public @property
    string numericString();

    abstract public @property
    void numericString(string value);

    // PrintableString
    abstract public @property
    string printableString();

    abstract public @property
    void printableString(string value);

    // TeletexString
    abstract public @property
    ubyte[] teletexString();

    abstract public @property
    void teletexString(ubyte[] value);

    // VideotexString
    abstract public @property
    ubyte[] videotexString();

    abstract public @property
    void videotexString(ubyte[] value);

    // IA5String
    abstract public @property
    string ia5String();

    abstract public @property
    void ia5String(string value);

    // UTCTime
    abstract public @property
    DateTime utcTime();

    abstract public @property
    void utcTime(DateTime value);

    // GeneralizedTime
    abstract public @property
    DateTime generalizedTime();

    abstract public @property
    void generalizedTime(DateTime value);

    // GraphicString
    abstract public @property
    string graphicString();

    abstract public @property
    void graphicString(string value);

    // VisibleString
    abstract public @property
    string visibleString();

    abstract public @property
    void visibleString(string value);

    // GeneralString
    abstract public @property
    string generalString();

    abstract public @property
    void generalString(string value);

    // UniversalString
    abstract public @property
    dstring universalString();

    abstract public @property
    void universalString(dstring value);

    // CHARACTER STRING
    abstract public @property
    CharacterString characterString();

    abstract public @property
    void characterString(CharacterString value);

    // BMPString
    abstract public @property
    wstring bmpString();

    abstract public @property
    void bmpString(wstring value);
}

//TODO: Implement isImaginary and isComplex in std.traits.
