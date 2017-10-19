/**
    The codecs in this library are values of an ASN1 encoding scheme.
    The type, length, and value are set using properties defined on
    abstract classes from which the encoding-specific values inherit.
    This module contains those abstract classes, and with these classes,
    it serves as the root module from which all other codec modules will
    inherit.
*/
module codec;
public import asn1;
public import types.alltypes;
// TODO: Remove dependency on std.outbuffer.
package import std.algorithm.mutation : reverse;
package import std.algorithm.searching : canFind;
package import std.ascii : isASCII, isGraphical;
package import std.bitmanip : BitArray;
package import std.datetime.date : DateTime;
private import std.exception : basicExceptionCtors;
package import std.math : log2;
package import std.outbuffer;
package import std.traits : isIntegral, isSigned;

///
public alias ASN1CodecException = AbstractSyntaxNotation1CodecException;
/// A generic exception from which any ASN.1 codec exception may inherit
public
class AbstractSyntaxNotation1CodecException : ASN1Exception
{
    mixin basicExceptionCtors;
}

///
public alias ASN1ValueSizeException = AbstractSyntaxNotation1ValueSizeException;
///
public
class AbstractSyntaxNotation1ValueSizeException : ASN1CodecException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1ValueTooBigException = AbstractSyntaxNotation1ValueTooBigException;
///
public
class AbstractSyntaxNotation1ValueTooBigException : ASN1ValueSizeException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1ValueTooSmallException = AbstractSyntaxNotation1ValueTooSmallException;
///
public
class AbstractSyntaxNotation1ValueTooSmallException : ASN1ValueSizeException
{
    mixin basicExceptionCtors;
}

///
public alias ASN1InvalidValueException = AbstractSyntaxNotation1InvalidValueException;
/**
    Thrown when an encoded value, or a decoded value (attempting to be encoded)
    takes on a value that the codec cannot encode or decode.

    Examples:
    $(UL
        $(LI When a DER codec detects a BOOLEAN encoded in a byte other than 0xFF or 0x00)
        $(LI When a )
    )
*/
public
class AbstractSyntaxNotation1InvalidValueException : ASN1CodecException
{
    mixin basicExceptionCtors; 
}

///
public alias ASN1InvalidIndexException = AbstractSyntaxNotation1InvalidIndexException;
/**
    An exception thrown when a member of a CHOICE or SEQUENCE is given a
    context-specific index that is not defined for that CHOICE or SEQUENCE.

    For example, if:

    TheQuestion := [APPLICATION 5] CHOICE {
        toBe [0] NULL,
        notToBe [1] NULL
    }

    This exception should be thrown if TheQuestion were to be decoded from the
    BER-encoded byte sequence: $(D_INLINECODE 0x65 0x02 0x83 0x00), because
    the third byte specifies a third choice in TheQuestion, but there is no
    choice #3 in TheQuestion--there is only choice #0 and #1.
*/
public
class AbstractSyntaxNotation1InvalidIndexException : ASN1CodecException
{
    mixin basicExceptionCtors; 
}

///
public alias ASN1InvalidLengthException = AbstractSyntaxNotation1InvalidLengthException;
/**
    Thrown if an invalid length encoding is encountered, such as when a length byte
    of 0xFF--which is reserved--is encountered in BER encoding.
*/
public
class AbstractSyntaxNotation1InvalidLengthException : ASN1CodecException
{
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

    /**
        Whether the value is one of the universally-defined data types, which
        are:

        $(TABLE
            $(TR $(TH Type)                 $(TH Construction)      $(TH Hexadecimal Value))
            $(TR $(TD End-of-Content)       $(TD Primitive)         $(TD 0x00))
            $(TR $(TD BOOLEAN)	            $(TD Primitive)         $(TD 0x01))
            $(TR $(TD INTEGER)	            $(TD Primitive)         $(TD 0x02))
            $(TR $(TD BIT STRING)           $(TD Both)              $(TD 0x03))
            $(TR $(TD OCTET STRING)         $(TD Both)              $(TD 0x04))
            $(TR $(TD NULL)                 $(TD Primitive)         $(TD 0x05))
            $(TR $(TD OBJECT IDENTIFIER)	$(TD Primitive)         $(TD 0x06))
            $(TR $(TD Object Descriptor)    $(TD Both)              $(TD 0x07))
            $(TR $(TD EXTERNAL)	            $(TD Constructed)       $(TD 0x08))
            $(TR $(TD REAL)            	    $(TD Primitive)         $(TD 0x09))
            $(TR $(TD ENUMERATED)	        $(TD Primitive)         $(TD 0x0A))
            $(TR $(TD EMBEDDED PDV)	        $(TD Constructed)       $(TD 0x0B))
            $(TR $(TD UTF8String)	        $(TD Both)              $(TD 0x0C))
            $(TR $(TD RELATIVE-OID)	        $(TD Primitive)         $(TD 0x0D))
            $(TR $(TD SEQUENCE)	            $(TD Constructed)       $(TD 0x10))
            $(TR $(TD SET)	                $(TD Constructed)       $(TD 0x11))
            $(TR $(TD NumericString)	    $(TD Both)              $(TD 0x12))
            $(TR $(TD PrintableString)	    $(TD Both)              $(TD 0x13))
            $(TR $(TD T61String)	        $(TD Both)              $(TD 0x14))
            $(TR $(TD VideotexString)	    $(TD Both)              $(TD 0x15))
            $(TR $(TD IA5String)	        $(TD Both)              $(TD 0x16))
            $(TR $(TD UTCTime)	            $(TD Both)              $(TD 0x17))
            $(TR $(TD GeneralizedTime)	    $(TD Both)              $(TD 0x18))
            $(TR $(TD GraphicString)	    $(TD Both)              $(TD 0x19))
            $(TR $(TD VisibleString)	    $(TD Both)              $(TD 0x1A))
            $(TR $(TD GeneralString)	    $(TD Both)              $(TD 0x1B))
            $(TR $(TD UniversalString)	    $(TD Both)              $(TD 0x1C))
            $(TR $(TD CHARACTER STRING)	    $(TD Both)              $(TD 0x1D))
            $(TR $(TD BMPString)	        $(TD Both)              $(TD 0x1E))
        )
    */
    final public @property
    bool universal()
    {
        return ((this.type & 0xC) == 0x00);
    }

    /**
        Whether the type is application-specific.
    */
    final public @property
    bool applicationSpecific()
    {
        return ((this.type & 0xC) == 0x40);
    }

    /**
        Whether the type tag specifies an index within a SEQUENCE or CHOICE.
    */
    final public @property
    bool contextSpecific()
    {
        return ((this.type & 0xC) == 0x80);
    }

    /// I don't know what this even means.
    final public @property
    bool privatelySpecific()
    {
        return ((this.type & 0xC) == 0x40);
    }

    /// The length of the value in octets
    final public @property @safe nothrow
    size_t length()
    {
        return this.value.length;
    }

    /// The octets of the encoded value.
    public ubyte[] value;

    // Convenience
    // pragma(inline, true);
    final private
    void throwIfEmptyValue(X : ASN1CodecException)()
    {
        if (this.length != 1) throw new X ("Value bytes was zero");
    }

    /**
        An opCast() override for converting the type-length-value tuple to
        bytes.
    */
    public
    ubyte[] opCast(T = ubyte[])()
    {
        return [];
    }

    /// Decodes a boolean
    abstract public @property
    bool boolean();

    /// Encodes a boolean
    abstract public @property
    void boolean(bool value);

    /// Decodes an integer
    abstract public @property
    T integer(T)() if (isIntegral!T && isSigned!T);

    /// Encodes an integer
    abstract public @property
    void integer(T)(T value) if (isIntegral!T && isSigned!T);

    /// Decodes a BitArray
    abstract public @property
    BitArray bitString();

    /// Encodes a BitArray
    abstract public @property
    void bitString(BitArray value);

    /// Decodes a ubyte[] array
    abstract public @property
    ubyte[] octetString();

    /// Encodes a ubyte[] array
    abstract public @property
    void octetString(ubyte[] value);

    ///
    public alias oid = objectIdentifier;
    /// Decodes an Object Identifier
    abstract public @property
    OID objectIdentifier();

    /// Encodes an Object Identifier
    abstract public @property
    void objectIdentifier(OID value);

    /**
        Decodes an ObjectDescriptor, which is a string consisting of only
        graphical characters. In fact, ObjectDescriptor is actually implicitly
        just a GraphicString! The formal specification for an ObjectDescriptor
        is:

        $(I ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        GraphicString is just 0x20 to 0x7E, therefore ObjectDescriptor is just
        0x20 to 0x7E.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)
    */
    abstract public @property
    string objectDescriptor();

    /**
        Encodes an ObjectDescriptor, which is a string consisting of only
        graphical characters. In fact, ObjectDescriptor is actually implicitly
        just a GraphicString! The formal specification for an ObjectDescriptor
        is:

        $(I ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        GraphicString is just 0x20 to 0x7E, therefore ObjectDescriptor is just
        0x20 to 0x7E.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)
    */
    abstract public @property
    void objectDescriptor(string value);

    /**
        Decodes an EXTERNAL, which is a constructed data type, defined in 
        the $(LINK2 https://www.itu.int, 
            International Telecommunications Union)'s 
        $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines EXTERNAL as:

        $(I
        EXTERNAL := [UNIVERSAL 8] IMPLICIT SEQUENCE {
            identification CHOICE {
                syntax OBJECT IDENTIFIER,
                presentation-context-id INTEGER,
                context-negotiation SEQUENCE {
                    presentation-context-id INTEGER,
                    transfer-syntax OBJECT IDENTIFIER } },
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 2.
    */
    abstract public @property
    External external();

    /**
        Encodes an EXTERNAL, which is a constructed data type, defined in 
        the $(LINK2 https://www.itu.int, 
            International Telecommunications Union)'s 
        $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines EXTERNAL as:

        $(I
        EXTERNAL := [UNIVERSAL 8] IMPLICIT SEQUENCE {
            identification CHOICE {
                syntax OBJECT IDENTIFIER,
                presentation-context-id INTEGER,
                context-negotiation SEQUENCE {
                    presentation-context-id INTEGER,
                    transfer-syntax OBJECT IDENTIFIER } },
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 2.
    */
    abstract public @property
    void external(External value);

    // TODO: Make string variants
    /// Encodes a floating-point number
    abstract public @property
    T realType(T)() if (is(T == float) || is(T == double));

    /// Encodes a floating-point number
    abstract public @property
    void realType(T)(T value) if (is(T == float) || is(T == double));

    /// Encodes an integer that represents an ENUMERATED value
    abstract public @property
    T enumerated(T)() if (isIntegral!T && isSigned!T);

    /// Decodes an integer that represents an ENUMERATED value
    abstract public @property
    void enumerated(T)(T value) if (isIntegral!T && isSigned!T);

    ///
    public alias embeddedPDV = embeddedPresentationDataValue;
    /**
        Decodes an EMBEDDED PDV, which is a constructed data type, defined in 
            the $(LINK2 https://www.itu.int, 
                International Telecommunications Union)'s 
            $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines EMBEDDED PDV as:

        $(I
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
            (WITH COMPONENTS { ... , data-value-descriptor ABSENT })
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 5.
    */
    abstract public @property
    EmbeddedPDV embeddedPresentationDataValue();

    /**
        Encodes an EMBEDDED PDV, which is a constructed data type, defined in 
            the $(LINK2 https://www.itu.int, 
                International Telecommunications Union)'s 
            $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines EMBEDDED PDV as:

        $(I
            EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                data-value-descriptor ObjectDescriptor OPTIONAL,
                data-value OCTET STRING }
            (WITH COMPONENTS { ... , data-value-descriptor ABSENT })
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 5.
    */
    abstract public @property
    void embeddedPresentationDataValue(EmbeddedPDV value);

    ///
    public alias utf8String = unicodeTransformationFormat8String;
    /// Decodes a UTF-8 String
    abstract public @property
    string unicodeTransformationFormat8String();

    /// Encodes a UTF-8 String
    abstract public @property
    void unicodeTransformationFormat8String(string value);

    ///
    public alias relativeOID = relativeObjectIdentifier;
    /// Decodes a portion of an Object Identifier
    abstract public @property
    RelativeOID relativeObjectIdentifier();

    /// Encodes a porition of an Object Identifier
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

    /**
        Decodes a string, where the characters of the string are limited to
        0 - 9 and space.
    */
    abstract public @property
    string numericString();

    /**
        Encodes a string, where the characters of the string are limited to
        0 - 9 and space.
    */
    abstract public @property
    void numericString(string value);

    /**
        Decodes a string that will only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period, 
        forward slash, colon, equals, and question mark.
    */
    abstract public @property
    string printableString();

    /**
        Encodes a string that will only contain characters a-z, A-Z, 0-9,
        space, apostrophe, parentheses, comma, minus, plus, period, 
        forward slash, colon, equals, and question mark.
    */
    abstract public @property
    void printableString(string value);

    ///
    public alias t61String = teletexString;
    /// Decodes bytes representing the T.61 Character Set
    abstract public @property
    ubyte[] teletexString();

    /// Encodes bytes representing the T.61 Character Set
    abstract public @property
    void teletexString(ubyte[] value);

    abstract public @property
    ubyte[] videotexString();

    abstract public @property
    void videotexString(ubyte[] value);

    ///
    public alias ia5String = internationalAlphabetNumber5String;
    /// Decodes a string of ASCII characters
    abstract public @property
    string internationalAlphabetNumber5String();

    /// Encodes a string of ASCII characters
    abstract public @property
    void internationalAlphabetNumber5String(string value);

    ///
    public alias utc = coordinatedUniversalTime;
    ///
    public alias utcTime = coordinatedUniversalTime;
    /// Decodes a DateTime
    abstract public @property
    DateTime coordinatedUniversalTime();

    /// Encodes a DateTime
    abstract public @property
    void coordinatedUniversalTime(DateTime value);

    /// Decodes a DateTime
    abstract public @property
    DateTime generalizedTime();

    /// Encodes a DateTime
    abstract public @property
    void generalizedTime(DateTime value);

    /**
        Decodes an ASCII string that contains only characters between and 
        including 0x20 and 0x75.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

    */
    abstract public @property
    string graphicString();

    /**
        Encodes an ASCII string that contains only characters between and 
        including 0x20 and 0x75.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

    */
    abstract public @property
    void graphicString(string value);

    /**
        Decodes a string that only contains characters between and including
        0x20 and 0x7E. (Honestly, I don't know how this differs from
        GraphicalString.)
    */
    abstract public @property
    string visibleString();

    /**
        Encodes a string that only contains characters between and including
        0x20 and 0x7E. (Honestly, I don't know how this differs from
        GraphicalString.)
    */
    abstract public @property
    void visibleString(string value);

    /// Decodes a string containing only ASCII characters.
    abstract public @property
    string generalString();

    /// Encodes a string containing only ASCII characters.
    abstract public @property
    void generalString(string value);

    /// Decodes a string of UTF-32 characters
    abstract public @property
    dstring universalString();

    /// Encodes a string of UTF-32 characters
    abstract public @property
    void universalString(dstring value);

    /**
        Decodes a CHARACTER STRING, which is a constructed data type, defined
        in the $(LINK2 https://www.itu.int, 
                International Telecommunications Union)'s 
            $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines CHARACTER as:

        $(I
            CHARACTER STRING ::= [UNIVERSAL 29] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                string-value OCTET STRING }
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 5.
    */
    abstract public @property
    CharacterString characterString();

    /**
        Encodes a CHARACTER STRING, which is a constructed data type, defined
        in the $(LINK2 https://www.itu.int, 
                International Telecommunications Union)'s 
            $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680).

        The specification defines CHARACTER as:

        $(I
            CHARACTER STRING ::= [UNIVERSAL 29] SEQUENCE {
                identification CHOICE {
                    syntaxes SEQUENCE {
                        abstract OBJECT IDENTIFIER,
                        transfer OBJECT IDENTIFIER },
                    syntax OBJECT IDENTIFIER,
                    presentation-context-id INTEGER,
                    context-negotiation SEQUENCE {
                        presentation-context-id INTEGER,
                        transfer-syntax OBJECT IDENTIFIER },
                    transfer-syntax OBJECT IDENTIFIER,
                    fixed NULL },
                string-value OCTET STRING }
        )

        This assumes AUTOMATIC TAGS, so all of the identification choices
        will be context-specific and numbered from 0 to 5.
    */
    abstract public @property
    void characterString(CharacterString value);

    ///
    public alias bmpString = basicMultilingualPlaneString;
    /// Decodes a string of UTF-16 characters
    abstract public @property
    wstring basicMultilingualPlaneString();

    /// Encodes a string of UTF-16 characters
    abstract public @property
    void basicMultilingualPlaneString(wstring value);
}