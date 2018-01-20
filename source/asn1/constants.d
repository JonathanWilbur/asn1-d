/**
    This file contains the constants and $(D enum)s used by the library.

    Authors:
    $(UL
        $(LI $(PERSON Jonathan M. Wilbur, jonathan@wilbur.space, http://jonathan.wilbur.space))
    )
    Copyright: Copyright (C) Jonathan M. Wilbur
    License: $(LINK https://mit-license.org/, MIT License)
    Standards:
        $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1))
    See_Also:
        $(LINK https://en.wikipedia.org/wiki/Abstract_Syntax_Notation_One, The Wikipedia Page on ASN.1)
        $(LINK https://www.strozhevsky.com/free_docs/asn1_in_simple_words.pdf, ASN.1 By Simple Words)
        $(LINK http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF, ASN.1: Communication Between Heterogeneous Systems)
*/
module asn1.constants;

/*
    Done to avoid the problems associated with CVE-2009-0789. I don't know this
    to be a bug with this code, but it is better to play on the safe side.
    Remove at your own peril.
*/
static assert(!(long.sizeof < (void *).sizeof));

debug (asn1)
{
    public import std.stdio : write, writefln, writeln;
}

version (unittest)
{
    public import core.exception : AssertError, RangeError;
    public import std.exception : assertNotThrown, assertThrown;
    public import std.math : approxEqual;
    public import std.stdio : write, writefln, writeln;
}

// Check fundamental assumptions of this library.
static assert(char.sizeof == 1u);
static assert(wchar.sizeof == 2u);
static assert(dchar.sizeof == 4u);
static assert(double.sizeof > float.sizeof);
static assert(real.sizeof >= double.sizeof);

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
immutable public
enum AbstractSyntaxNotation1TagClass : ubyte
{
    universal = 0b00000000u, // Native to ASN.1
    application = 0b01000000u, // Only valid for one specific application
    contextSpecific = 0b10000000u, // Specific to a sequence, set, or choice
    privatelyDefined = 0b11000000u// Defined in private specifications
}

///
public alias ASN1Construction = AbstractSyntaxNotation1Construction;
///
immutable public
enum AbstractSyntaxNotation1Construction : ubyte
{
    primitive = 0b00000000u, // The content octets directly encode the element value
    constructed = 0b00100000u // The content octets contain 0, 1, or more element encodings
}

///
public alias ASN1UniversalType = AbstractSyntaxNotation1UniversalType;
/**
    The data types, as well as their permitted construction and numeric
    identifiers, according to the
    $(LINK https://www.itu.int/en/pages/default.aspx,
    International Telecommunications Union)'s
    $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules)

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
        $(TR $(TD EmbeddedPDV)	        $(TD Constructed)       $(TD 0x0B))
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
immutable public
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
    realNumber = 0x09u,
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
    definiteShort = 0b00000000u, // Least significant seven bits of length octet encode content length of 0 - 127 bytes
    indefinite = 0b10000000u, // Content ends when two endOfContent bytes are encountered.
    definiteLong = 0b10000001u, // Least significant seven bits of length octet encode how many more length octets
    reserved = 0b11111111u
}

///
public alias ASN1RealEncodingBase = AbstractSyntaxNotation1RealEncodingBase;
///
immutable public
enum AbstractSyntaxNotation1RealEncodingBase : ubyte
{
    base2 = 0x02u,
    base8 = 0x08u,
    base10 = 0x0Au,
    base16 = 0x10u
}

///
public alias ASN1RealEncodingScale = AbstractSyntaxNotation1RealEncodingScale;
///
immutable public
enum AbstractSyntaxNotation1RealEncodingScale : ubyte
{
    scale0 = 0x00u,
    scale1 = 0x01u,
    scale2 = 0x02u,
    scale3 = 0x03u
}

///
public alias ASN1RealExponentEncoding = AbstractSyntaxNotation1RealExponentEncoding;
///
immutable public
enum AbstractSyntaxNotation1RealExponentEncoding : ubyte
{
    followingOctet = 0b00000000u,
    following2Octets = 0b00000001u,
    following3Octets = 0b00000010u,
    complicated = 0b00000011u // Just calling it as I see it.
}

///
public alias ASN1SpecialRealValue = AbstractSyntaxNotation1SpecialRealValue;
/**
    Special values for REALs, as assigned in section 8.5.9 of X.690.

    Note that NOT-A-NUMBER and minus zero were added in the 2015 version.
*/
immutable public
enum AbstractSyntaxNotation1SpecialRealValue : ubyte
{
    plusInfinity = 0b01000000u,
    minusInfinity = 0b01000001u,
    notANumber = 0b01000010u,
    minusZero = 0b01000011u
}

///
public alias ASN1Base10RealNumericalRepresentation = AbstractSyntaxNotation1Base10RealNumericalRepresentation;
/**
    The standardized string representations of floating point numbers, as
    specified in $(LINK https://www.iso.org/standard/12285.html, ISO 6093).

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
immutable public
enum AbstractSyntaxNotation1Base10RealNumericalRepresentation : ubyte
{
    nr1 = 0b00000001u,
    nr2 = 0b00000010u,
    nr3 = 0b00000011
}

/// The acceptable characters for a NumericString
immutable public string numericStringCharacters = "0123456789 ";

/**
    The acceptable characters for a printableString.

    The sorting of letters below is a slight optimization:
    they are sorted in order of decreasing frequency in the English
    language, so that canFind will usually have to iterate through
    fewer letters before finding a match.
*/
immutable public string printableStringCharacters =
    "etaoinsrhdlucmfywgpbvkxqjzETAOINSRHDLUCMFYWGPBVKXQJZ0123456789 '()+,-./:=?";