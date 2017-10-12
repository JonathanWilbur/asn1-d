module asn1;

//TODO: Disable default constructor for all types!

/// A Generic Exception from which all other ASN.1 Exceptions will inherit.
class ASN1Exception : Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

public
enum ASN1TagClass : ubyte
{
    universal = 0b00000000, // Native to ASN.1
    application = 0b01000000, // Only valid for one specific application
    contextSpecific = 0b10000000, // Specific to a sequence, set, or choice
    privatelyDefined = 0b11000000 // Defined in private specifications
}

public
enum ASN1PC : ubyte
{
    primitive = 0b00000000, // The content octets directly encode the element value
    constructed = 0b00100000 // The content octets contain 0, 1, or more element encodings
}

public
enum ASN1Length : ubyte
{
    definiteShort, // Least significant seven bits of length octet encode content length of 0 - 127 bytes
    indefinite, // Content ends when two endOfContent bytes are encountered.
    definiteLong, // Least significant seven bits of length octet encode how many more length octets
    reserved // 0b11111111
}

enum RealEncodingBase : ubyte
{
    base2 = 0x02,
    base8 = 0x08,
    base10 = 0x0A,
    base16 = 0x10
}

enum RealBinaryEncodingBase : ubyte
{
    base2 = 0b00000000,
    base8 = 0b00010000,
    base16 = 0b00100000
}

enum RealEncodingScale : ubyte
{
    scale0 = 0x00,
    scale1 = 0x01,
    scale2 = 0x02,
    scale3 = 0x03
}

enum RealEncodingScales : ubyte //TODO: Rename this
{
    scale0 = 0b00000000,
    scale1 = 0b00000100,
    scale2 = 0b00001000,
    scale3 = 0b00001100
}

enum RealExponentEncoding : ubyte
{
    followingOctet = 0b00000000,
    following2Octets = 0b00000001,
    following3Octets = 0b00000010,
    complicated = 0b00000011 // Just calling it as I see it.
}

enum SpecialRealValue : ubyte
{
    plusInfinity = 0b01000000,
    minusInfinity = 0b01000001,
    notANumber = 0b01000010,
    negativeZero = 0b01000011
}

// These values come from ISO 6093
// TODO: Cite this, page 143 of ASN.1 Book
enum Base10RealNumericalRepresentation : ubyte
{
    nr1 = 0b0000_0001, // "3", "-1", "+1000" - Fixed, implicit decimal point
    nr2 = 0b0000_0010, // "3.0", "-1.3", "-.3" - Explicit decimal
    nr3 = 0b0000_0011 // "3.0E1", "123E+100" - Explicit exponent
}

enum Base10RealDecimalSeparator : char
{
    period = '.',
    comma = ','
}

enum Base10RealExponentCharacter : char
{
    lowercaseE = 'e',
    uppercaseE = 'E'
}
