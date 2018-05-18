// D import file generated from '.\source\asn1\constants.d'
module asn1.constants;
static assert(!((long).sizeof < (void*).sizeof));
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
static assert((char).sizeof == 1u);
static assert((wchar).sizeof == 2u);
static assert((dchar).sizeof == 4u);
static assert((double).sizeof > (float).sizeof);
static assert((real).sizeof >= (double).sizeof);
public alias ASN1Exception = AbstractSyntaxNotation1Exception;
class AbstractSyntaxNotation1Exception : Exception
{
	private import std.exception : basicExceptionCtors;
	mixin basicExceptionCtors!();
}
public alias ASN1TagClass = AbstractSyntaxNotation1TagClass;
immutable public enum AbstractSyntaxNotation1TagClass : ubyte
{
	universal = 0u,
	application = 64u,
	contextSpecific = 128u,
	privatelyDefined = 192u,
}
public alias ASN1Construction = AbstractSyntaxNotation1Construction;
immutable public enum AbstractSyntaxNotation1Construction : ubyte
{
	primitive = 0u,
	constructed = 32u,
}
public alias ASN1UniversalType = AbstractSyntaxNotation1UniversalType;
immutable public enum AbstractSyntaxNotation1UniversalType : ubyte
{
	endOfContent = 0u,
	eoc = endOfContent,
	boolean = 1u,
	integer = 2u,
	bitString = 3u,
	octetString = 4u,
	nill = 5u,
	objectIdentifier = 6u,
	oid = objectIdentifier,
	objectDescriptor = 7u,
	external = 8u,
	ext = external,
	realNumber = 9u,
	enumerated = 10u,
	embeddedPresentationDataValue = 11u,
	embeddedPDV = embeddedPresentationDataValue,
	pdv = embeddedPresentationDataValue,
	unicodeTransformationFormat8String = 12u,
	utf8String = unicodeTransformationFormat8String,
	utf8 = unicodeTransformationFormat8String,
	relativeObjectIdentifier = 13u,
	relativeOID = relativeObjectIdentifier,
	roid = relativeObjectIdentifier,
	reserved14 = 14u,
	reserved15 = 15u,
	sequence = 16u,
	set = 17u,
	numericString = 18u,
	numeric = numericString,
	printableString = 19u,
	printable = printableString,
	teletexString = 20u,
	t61String = teletexString,
	videotexString = 21u,
	internationalAlphabetNumber5String = 22u,
	ia5String = internationalAlphabetNumber5String,
	coordinatedUniversalTime = 23u,
	utcTime = coordinatedUniversalTime,
	generalizedTime = 24u,
	graphicString = 25u,
	graphic = graphicString,
	visibleString = 26u,
	visible = visibleString,
	generalString = 27u,
	general = generalString,
	universalString = 28u,
	universal = universalString,
	characterString = 29u,
	basicMultilingualPlaneString = 30u,
	bmpString = basicMultilingualPlaneString,
}
public alias ASN1LengthEncoding = AbstractSyntaxNotation1LengthEncoding;
public enum AbstractSyntaxNotation1LengthEncoding : ubyte
{
	definiteShort = 0u,
	indefinite = 128u,
	definiteLong = 129u,
	reserved = 255u,
}
public alias ASN1RealEncodingBase = AbstractSyntaxNotation1RealEncodingBase;
immutable public enum AbstractSyntaxNotation1RealEncodingBase : ubyte
{
	base2 = 2u,
	base8 = 8u,
	base10 = 10u,
	base16 = 16u,
}
public alias ASN1RealEncodingScale = AbstractSyntaxNotation1RealEncodingScale;
immutable public enum AbstractSyntaxNotation1RealEncodingScale : ubyte
{
	scale0 = 0u,
	scale1 = 1u,
	scale2 = 2u,
	scale3 = 3u,
}
public alias ASN1RealExponentEncoding = AbstractSyntaxNotation1RealExponentEncoding;
immutable public enum AbstractSyntaxNotation1RealExponentEncoding : ubyte
{
	followingOctet = 0u,
	following2Octets = 1u,
	following3Octets = 2u,
	complicated = 3u,
}
public alias ASN1SpecialRealValue = AbstractSyntaxNotation1SpecialRealValue;
immutable public enum AbstractSyntaxNotation1SpecialRealValue : ubyte
{
	plusInfinity = 64u,
	minusInfinity = 65u,
	notANumber = 66u,
	minusZero = 67u,
}
public alias ASN1Base10RealNumericalRepresentation = AbstractSyntaxNotation1Base10RealNumericalRepresentation;
immutable public enum AbstractSyntaxNotation1Base10RealNumericalRepresentation : ubyte
{
	nr1 = 1u,
	nr2 = 2u,
	nr3 = 3,
}
public immutable string numericStringCharacters = "0123456789 ";
public immutable string printableStringCharacters = "etaoinsrhdlucmfywgpbvkxqjzETAOINSRHDLUCMFYWGPBVKXQJZ0123456789 '()+,-./:=?";
