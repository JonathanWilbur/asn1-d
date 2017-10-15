/**
    The codecs in this library are values of an ASN1 encoding scheme.
    The type, length, and value are set using properties defined on
    abstract classes from which the encoding-specific values inherit.
    This module contains those abstract classes, and with these classes,
    it serves as the root module from which all other codec modules will
    inherit.
*/
module codec;
import asn1;
import types.alltypes;
package import std.algorithm.mutation : reverse;
package import std.algorithm.searching : canFind;
package import std.ascii : isASCII, isGraphical;
package import std.bitmanip : BitArray;
package import std.datetime.date : DateTime;
package import std.math : log2;
package import std.outbuffer;
package import std.traits : isIntegral;

class ASN1CodecException : ASN1Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

///
public alias ASN1Value = AbstractSyntaxNotation1Value;
/// An abstract class from which both ASN1BinaryCodec and ASN1TextCodec will inherit.
abstract public
class AbstractSyntaxNotation1Value
{

}

// REVIEW: Should the setters return booleans indicating success instead of throwing errors?
///
public alias ASN1BinaryValue = AbstractSyntaxNotation1BinaryValue;
///
abstract public
class AbstractSyntaxNotation1BinaryValue : ASN1Value
{

    /* TODO:
        Make a "foolproof" version that makes value a private member, so that
        it can only be assigned values via legitimate properties.
        ... if that's possible.
    */
    // NOTE: Storage classes are basically going to be impossible with properties...

    // Constants used to save CPU cycles
    private immutable real maxUintAsReal = cast(real) uint.max; // Saves CPU cycles in encodeReal()
    private immutable real maxUlongAsReal = cast(real) ulong.max; // Saves CPU cycles in encodeReal()
    private immutable real logBaseTwoOfTen = log2(10.0); // Saves CPU cycles in encodeReal()

    // Settings

    ///
    public
    enum LengthEncodingPreference
    {
        definite,
        indefinite
    }

    /**
        Unlike most other settings, this is non-static, because wanting to
        encode with indefinite length is probably going to be somewhat rare,
        and it is also less safe, because the value octets have to be inspected
        for double octets before encoding! (If they are not, the receiver will 
        interpret those inner null octets as the terminator for the indefinite
        length value, and the rest will be truncated.)
    */
    public LengthEncodingPreference lengthEncodingPreference = 
        LengthEncodingPreference.definite;

    /**
        Whether the base 10 / character-encoded representation of a REAL
        should prepend a plus sign if the value is positive.
    */
    static public bool base10RealShouldShowPlusSignIfPositive = false;

    /**
        Whether a comma or a period is used to separate the whole and
        fractional components of the base 10 / character-encoded representation
        of a REAL.
    */
    static public ASN1Base10RealDecimalSeparator base10RealDecimalSeparator = 
        ASN1Base10RealDecimalSeparator.period;

    /**
        Whether a capital or lowercase E is used to separate the significand
        from the exponent in the base 10 / character-encoded representation
        of a REAL.
    */
    static public ASN1Base10RealExponentCharacter base10RealExponentCharacter = 
        ASN1Base10RealExponentCharacter.uppercaseE;

    /**
        The standardized string representations of floating point numbers, as 
        specified in $(LINK2 https://www.iso.org/standard/12285.html, ISO 6093).

        $(TABLE
            $(TR $(TH Representation) $(TH Description) $(TH Examples))
            $(TR $(TD NR1) $(TD Implicit decimal point) $(TD "3", "-1", "+1000"))
            $(TR $(TD NR2) $(TD Explicit decimal) $(TD "3.0", "-1.3", "-.3"))
            $(TR $(TD NR3) $(TD Explicit exponent) $(TD "3.0E1", "123E+100"))
        )

        Source:
            Page 143 of Dubuisson's ASN.1 Book
    */
    static public ASN1Base10RealNumericalRepresentation base10RealNumericalRepresentation = 
        ASN1Base10RealNumericalRepresentation.nr3;

    /// The base of encoded REALs. May be 2, 8, 10, or 16.
    static public ASN1RealEncodingBase realEncodingBase = ASN1RealEncodingBase.base2;

    /// The base of binary-encoded REALs. May be 2, 8, or 16.
    static public ASN1RealBinaryEncodingBase realBinaryEncodingBase = ASN1RealBinaryEncodingBase.base2;
    // TODO: maximumValueLength (to prevent DoS attacks)

    // public ASN1TypeTag type;
    public ubyte type;

    final public @property
    bool universal()
    {
        return ((this.type & 0xC) == 0x00);
    }

    final public @property
    bool applicationSpecific()
    {
        return ((this.type & 0xC) == 0x40);
    }

    final public @property
    bool contextSpecific()
    {
        return ((this.type & 0xC) == 0x80);
    }

    final public @property
    bool privatelySpecific()
    {
        return ((this.type & 0xC) == 0x40);
    }

    final public @property @safe nothrow
    size_t length()
    {
        return this.value.length;
    }

    public ubyte[] value;

    // Convenience
    // pragma(inline, true);
    final private
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
