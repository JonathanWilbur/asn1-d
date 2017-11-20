/**
    Abstract Syntax Notation 1 is a high-level syntax specification created
    by the $(LINK2 http://www.itu.int/en/pages/default.aspx, 
    International Telecommunications Union) in 
    $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, 
    X.680 - Abstract Syntax Notation One (ASN.1)), that
    abstractly defines data structures and protocol data units used by
    programs and protocols. It defines an extensible system of data types, 
    modules, and data structures.
    
    While described abstractly by ASN.1, the specified protocol data units 
    and data structures can be encoded via various encoding schemes, such as
    the Basic Encoding Rules (BER), which are defined in the
    $(LINK2 http://www.itu.int/en/pages/default.aspx, 
    International Telecommunications Union)'s
    $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules).
    These encoding schemes uniformly relay data between systems that
    can differ in endianness, bit-width, byte-size, operating system, 
    machine architecture, and so on.

    The encoding schemata that inherit from ASN.1 are used widely in protocols
    such as TLS, LDAP, SNMP, RDP, and many more.

    Author: 
        $(LINK2 http://jonathan.wilbur.space, Jonathan M. Wilbur) 
            $(LINK2 mailto:jonathan@wilbur.space, jonathan@wilbur.space)
    License: $(LINK2 https://mit-license.org/, MIT License)
    Standards:
        $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1))
    See_Also:
        $(LINK2 https://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One, The Wikipedia Page on ASN.1)
        $(LINK2 https://www.strozhevsky.com/free_docs/asn1_in_simple_words.pdf, ASN.1 By Simple Words)
        $(LINK2 http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF, ASN.1: Communication Between Heterogeneous Systems)
*/
module asn1;

debug(asn1)
{
    public import std.stdio : write, writefln, writeln;
}

version (unittest)
{
    public import core.exception : AssertError, RangeError;
    public import std.exception : assertNotThrown, assertThrown;
    public import std.math : approxEqual;
}

public import std.array : appender, Appender;

// Check fundamental assumptions of this library.
static assert(char.sizeof == 1u);
static assert(wchar.sizeof == 2u);
static assert(dchar.sizeof == 4u);

///
public alias ASN1Exception = AbstractSyntaxNotation1Exception;
/// A Generic Exception from which all other ASN.1 Exceptions will inherit.
class AbstractSyntaxNotation1Exception : Exception
{
    private import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

///
public alias ASN1TagClass = AbstractSyntaxNotation1TagClass;
///
public
enum AbstractSyntaxNotation1TagClass : ubyte
{
    universal = 0b00000000, // Native to ASN.1
    application = 0b01000000, // Only valid for one specific application
    contextSpecific = 0b10000000, // Specific to a sequence, set, or choice
    privatelyDefined = 0b11000000 // Defined in private specifications
}

///
public alias ASN1Construction = AbstractSyntaxNotation1Construction;
///
public
enum AbstractSyntaxNotation1Construction : ubyte
{
    primitive = 0b00000000, // The content octets directly encode the element value
    constructed = 0b00100000 // The content octets contain 0, 1, or more element encodings
}

///
public alias ASN1UniversalType = AbstractSyntaxNotation1UniversalType;
/**
    The data types, as well as their permitted construction and numeric
    identifiers, according to the 
    $(LINK2 http://www.itu.int/en/pages/default.aspx, 
    International Telecommunications Union)'s
    $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

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
public
enum AbstractSyntaxNotation1UniversalType : ubyte
{
    endOfContent = 0x00u,
    eoc = endOfContent,
    boolean = 0x01u,
    integer = 0x02u,
    bitString = 0x03u,
    octetString = 0x04u,
    nill = 0x05u,
    objectIdentifier = 0x06u,
    oid = objectIdentifier,
    objectDescriptor = 0x07u,
    external = 0x08u,
    ext = external,
    realType = 0x09u,
    enumerated = 0x0Au,
    embeddedPresentationDataValue = 0x0Bu,
    embeddedPDV = embeddedPresentationDataValue,
    pdv = embeddedPresentationDataValue,
    unicodeTransformationFormat8String = 0x0Cu,
    utf8String = unicodeTransformationFormat8String,
    utf8 = unicodeTransformationFormat8String,
    relativeObjectIdentifier = 0x0Du,
    relativeOID = relativeObjectIdentifier,
    roid = relativeObjectIdentifier,
    reserved14 = 0x0Eu,
    reserved15 = 0x0Fu,
    sequence = 0x10u,
    set = 0x11u,
    numericString = 0x12u,
    numeric = numericString,
    printableString = 0x13u,
    printable = printableString,
    teletexString = 0x14u,
    t61String = teletexString,
    videotexString = 0x15u,
    internationalAlphabetNumber5String = 0x16u,
    ia5String = internationalAlphabetNumber5String,
    coordinatedUniversalTime = 0x17u,
    utcTime = coordinatedUniversalTime,
    generalizedTime = 0x18u,
    graphicString = 0x19u,
    graphic = graphicString,
    visibleString = 0x1Au,
    visible = visibleString,
    generalString = 0x1Bu,
    general = generalString,
    universalString = 0x1Cu,
    universal = universalString,
    characterString = 0x1Du,
    basicMultilingualPlaneString = 0x1Eu,
    bmpString = basicMultilingualPlaneString
}

///
public alias ASN1LengthEncoding = AbstractSyntaxNotation1LengthEncoding;
///
public
enum AbstractSyntaxNotation1LengthEncoding : ubyte
{
    definiteShort, // Least significant seven bits of length octet encode content length of 0 - 127 bytes
    indefinite, // Content ends when two endOfContent bytes are encountered.
    definiteLong, // Least significant seven bits of length octet encode how many more length octets
    reserved // 0b11111111
}

///
public alias ASN1RealEncodingBase = AbstractSyntaxNotation1RealEncodingBase;
///
public
enum AbstractSyntaxNotation1RealEncodingBase : ubyte
{
    base2 = 0x02,
    base8 = 0x08,
    base10 = 0x0A,
    base16 = 0x10
}

///
public alias ASN1RealEncodingScale = AbstractSyntaxNotation1RealEncodingScale;
///
public
enum AbstractSyntaxNotation1RealEncodingScale : ubyte
{
    scale0 = 0x00,
    scale1 = 0x01,
    scale2 = 0x02,
    scale3 = 0x03
}

///
public alias ASN1RealExponentEncoding = AbstractSyntaxNotation1RealExponentEncoding;
///
public
enum AbstractSyntaxNotation1RealExponentEncoding : ubyte
{
    followingOctet = 0b00000000,
    following2Octets = 0b00000001,
    following3Octets = 0b00000010,
    complicated = 0b00000011 // Just calling it as I see it.
}

///
public alias ASN1SpecialRealValue = AbstractSyntaxNotation1SpecialRealValue;
///
public
enum AbstractSyntaxNotation1SpecialRealValue : ubyte
{
    plusInfinity = 0b01000000,
    minusInfinity = 0b01000001,
    notANumber = 0b01000010,
    negativeZero = 0b01000011
}

///
public alias ASN1Base10RealNumericalRepresentation = AbstractSyntaxNotation1Base10RealNumericalRepresentation;
/**
    The standardized string representations of floating point numbers, as 
    specified in $(LINK2 https://www.iso.org/standard/12285.html, ISO 6093).

    $(TABLE
        $(TR $(TH Representation) $(TH Description) $(TH Examples))
        $(TR $(TD NR1) $(TD Implicit decimal point) $(TD "3", "-1", "+1000"))
        $(TR $(TD NR2) $(TD Explicit decimal) $(TD "3.0", "-1.3", "-.3"))
        $(TR $(TD NR3) $(TD Explicit exponent) $(TD "3.0E1", "123E+100"))
    )

    Citations:
        Dubuisson, Olivier. “Character String Types.” ASN.1: 
            Communication between Heterogeneous Systems, Morgan 
            Kaufmann, 2001, p. 143.
*/
public
enum AbstractSyntaxNotation1Base10RealNumericalRepresentation : ubyte
{
    nr1 = 0b0000_0001,
    nr2 = 0b0000_0010,
    nr3 = 0b0000_0011
}

///
public alias ASN1Base10RealDecimalSeparator = AbstractSyntaxNotation1Base10RealDecimalSeparator;
///
enum AbstractSyntaxNotation1Base10RealDecimalSeparator : char
{
    period = '.',
    comma = ','
}

///
public alias ASN1Base10RealExponentCharacter = AbstractSyntaxNotation1Base10RealExponentCharacter;
///
enum AbstractSyntaxNotation1Base10RealExponentCharacter : char
{
    lowercaseE = 'e',
    uppercaseE = 'E'
}

/// The acceptable characters for a NumericString
public immutable string numericStringCharacters = "0123456789 ";

/**
    The acceptable characters for a printableString.

    The sorting of letters below is a slight optimization:
    they are sorted in order of decreasing frequency in the English
    language, so that canFind will usually have to iterate through
    fewer letters before finding a match.
*/
public immutable string printableStringCharacters = 
    "etaoinsrhdlucmfywgpbvkxqjzETAOINSRHDLUCMFYWGPBVKXQJZ0123456789 '()+,-./:=?";