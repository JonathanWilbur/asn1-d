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
    License: $(https://opensource.org/licenses/ISC, ISC License)
    Standards:
        $(LINK2 https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1))
    See_Also:
        $(LINK2 https://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One, The Wikipedia Page on ASN.1)
        $(LINK2 https://www.strozhevsky.com/free_docs/asn1_in_simple_words.pdf, ASN.1 By Simple Words)
        $(LINK2 http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF, ASN.1: Communication Between Heterogeneous Systems)
*/
module asn1;

debug
{
    public import std.stdio : writefln, writeln;
}

version (unittest)
{
    public import std.exception : assertThrown;
}

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
//
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
public alias ASN1RealBinaryEncodingBase = AbstractSyntaxNotation1RealBinaryEncodingBase;
///
public
enum AbstractSyntaxNotation1RealBinaryEncodingBase : ubyte
{
    base2 = 0b00000000,
    base8 = 0b00010000,
    base16 = 0b00100000
}

/* FIXME:
    Duplicates:
    ASN1RealEncodingScale
    ASN1RealEncodingScales

    Get rid of one.
*/
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
public alias ASN1RealEncodingScales = AbstractSyntaxNotation1RealEncodingScales;
///
public
enum AbstractSyntaxNotation1RealEncodingScales : ubyte //TODO: Rename this
{
    scale0 = 0b00000000,
    scale1 = 0b00000100,
    scale2 = 0b00001000,
    scale3 = 0b00001100
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

    Source:
        Page 143 of Dubuisson's ASN.1 Book
*/
public
enum AbstractSyntaxNotation1Base10RealNumericalRepresentation : ubyte
{
    nr1 = 0b0000_0001,
    nr2 = 0b0000_0010,
    nr3 = 0b0000_0011
}

// TODO: Make the default determined by locale
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