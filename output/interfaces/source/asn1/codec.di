// D import file generated from '.\source\asn1\codec.d'
module asn1.codec;
public import asn1.constants;
public import asn1.types.alltypes;
public import asn1.types.identification;
public import asn1.types.oidtype;
public import std.algorithm.mutation : reverse;
public import std.algorithm.searching : canFind;
public import std.array : appender, Appender, replace, split;
public import std.ascii : isASCII, isGraphical;
public import std.bigint : BigInt;
public import std.conv : text, to;
public import std.datetime.date : DateTime;
public import std.datetime.systime : SysTime;
public import std.datetime.timezone : TimeZone, UTC;
private import std.exception : basicExceptionCtors;
public import std.math : isIdentical, isNaN, log2;
public import std.string : indexOf;
public import std.traits : isFloatingPoint, isIntegral, isSigned, isUnsigned;
public alias ASN1CodecException = AbstractSyntaxNotation1CodecException;
public class AbstractSyntaxNotation1CodecException : ASN1Exception
{
	mixin basicExceptionCtors!();
}
public alias ASN1RecursionException = AbstractSyntaxNotation1RecursionException;
public class AbstractSyntaxNotation1RecursionException : ASN1CodecException
{
	immutable size_t recursionLimit;
	public pure @safe this(size_t recursionLimit, string whatYouAttemptedToDo, string file = __FILE__, size_t line = __LINE__)
	{
		this.recursionLimit = recursionLimit;
		super("This exception was thrown because you attempted to " ~ whatYouAttemptedToDo ~ ", which exceeded the recursion limit. " ~ "The recursion limit was " ~ text(this.recursionLimit) ~ ". This may indicate a malicious " ~ "attempt to compromise your application.", file, line);
	}
}
public alias ASN1TruncationException = AbstractSyntaxNotation1TruncationException;
public class AbstractSyntaxNotation1TruncationException : ASN1CodecException
{
	immutable size_t expectedBytes;
	immutable size_t actualBytes;
	public pure @safe this(size_t expectedBytes, size_t actualBytes, string whatYouAttemptedToDo, string file = __FILE__, size_t line = __LINE__)
	{
		version (unittest)
		{
			assert(actualBytes < expectedBytes);
		}

		this.expectedBytes = expectedBytes;
		this.actualBytes = actualBytes;
		super("This exception was thrown because you attempted to decode an " ~ "encoded ASN.1 element that was encoded on too few bytes. In " ~ "other words, it appears to have been truncated. While this " ~ "could indicate an attempt to compromise your application, " ~ "it is more likely that you were receiving encoded data from " ~ "a remote host, and that you have not received the entirety " ~ "of the data over the network yet. Based on the data decoded " ~ "so far, it looks like you needed at least " ~ text(expectedBytes) ~ " byte(s) of data, but only had " ~ text(actualBytes) ~ " byte(s) of data. This exception was thrown " ~ "when you were trying to " ~ whatYouAttemptedToDo ~ ".", file, line);
	}
}
public alias ASN1TagException = AbstractSyntaxNotation1TagException;
public class AbstractSyntaxNotation1TagException : ASN1CodecException
{
	mixin basicExceptionCtors!();
}
public alias ASN1TagOverflowException = AbstractSyntaxNotation1TagOverflowException;
public class AbstractSyntaxNotation1TagOverflowException : ASN1TagException
{
	mixin basicExceptionCtors!();
}
public alias ASN1TagPaddingException = AbstractSyntaxNotation1TagPaddingException;
public class AbstractSyntaxNotation1TagPaddingException : ASN1TagException
{
	mixin basicExceptionCtors!();
}
public alias ASN1TagClassException = AbstractSyntaxNotation1TagClassException;
public class AbstractSyntaxNotation1TagClassException : ASN1TagException
{
	const ASN1TagClass[] expectedTagClasses;
	immutable ASN1TagClass actualTagClass;
	public pure @safe this(ASN1TagClass[] expectedTagClasses, ASN1TagClass actualTagClass, string whatYouAttemptedToDo, string file = __FILE__, size_t line = __LINE__)
	{
		this.expectedTagClasses = expectedTagClasses;
		this.actualTagClass = actualTagClass;
		super("This exception was thrown because you attempted to decode or " ~ "encode an ASN.1 element with the wrong tag class. " ~ "This occurred when you were trying to " ~ whatYouAttemptedToDo ~ ". " ~ "The permitted tag classes are: " ~ text(expectedTagClasses) ~ "\x0a" ~ "The offending tag class was: " ~ text(actualTagClass), file, line);
	}
}
public alias ASN1ConstructionException = AbstractSyntaxNotation1ConstructionException;
public class AbstractSyntaxNotation1ConstructionException : ASN1TagException
{
	immutable ASN1Construction actualConstruction;
	public pure @safe this(ASN1Construction actualConstruction, string whatYouAttemptedToDo, string file = __FILE__, size_t line = __LINE__)
	{
		this.actualConstruction = actualConstruction;
		super("This exception was thrown because you attempted to decode an " ~ "encoded ASN.1 element that was encoded with the wrong construction. " ~ "This occurred when you were trying to " ~ whatYouAttemptedToDo ~ ". " ~ "The offending construction was: " ~ text(actualConstruction), file, line);
	}
}
public alias ASN1TypeException = AbstractSyntaxNotation1TagNumberException;
public alias ASN1TagNumberException = AbstractSyntaxNotation1TagNumberException;
public class AbstractSyntaxNotation1TagNumberException : ASN1TagException
{
	immutable size_t expectedTagNumber;
	immutable size_t actualTagNumber;
	public pure @safe this(size_t[] expectedTagNumbers, size_t actualTagNumber, string whatYouAttemptedToDo, string file = __FILE__, size_t line = __LINE__)
	{
		version (unittest)
		{
			assert(expectedTagNumber != actualTagNumber);
		}

		this.expectedTagNumber = expectedTagNumber;
		this.actualTagNumber = actualTagNumber;
		super("This exception was thrown because you attempted to decode an " ~ "encoded ASN.1 element that was encoded with the wrong tag number. " ~ "This occurred when you were trying to " ~ whatYouAttemptedToDo ~ ". " ~ "The offending tag number was: " ~ text(actualTagNumber) ~ "\x0a" ~ "The acceptable tag numbers are: " ~ text(expectedTagNumbers) ~ "\x0a", file, line);
	}
}
public alias ASN1LengthException = AbstractSyntaxNotation1LengthException;
public class AbstractSyntaxNotation1LengthException : ASN1CodecException
{
	mixin basicExceptionCtors!();
}
public alias ASN1LengthOverflowException = AbstractSyntaxNotation1LengthOverflowException;
public class AbstractSyntaxNotation1LengthOverflowException : ASN1LengthException
{
	public pure @safe this(string file = __FILE__, size_t line = __LINE__)
	{
		super("This exception was thrown because you attempted to decode an " ~ "ASN.1 encoded element whose length was too large to fit into " ~ "size_t.sizeof bytes.", file, line);
	}
}
public alias ASN1LengthUndefinedException = AbstractSyntaxNotation1LengthUndefinedException;
public class AbstractSyntaxNotation1LengthUndefinedException : ASN1LengthException
{
	public pure @safe this(string file = __FILE__, size_t line = __LINE__)
	{
		super("This exception was thrown because you attempted to decode an " ~ "ASN.1 encoded element whose length tag was 0xFF, which is " ~ "reserved by the specification.", file, line);
	}
}
public alias ASN1ValueException = AbstractSyntaxNotation1ValueException;
public class AbstractSyntaxNotation1ValueException : ASN1CodecException
{
	mixin basicExceptionCtors!();
}
public alias ASN1ValueSizeException = AbstractSyntaxNotation1ValueSizeException;
public class AbstractSyntaxNotation1ValueSizeException : ASN1ValueException
{
	immutable size_t min;
	immutable size_t max;
	immutable size_t actual;
	public nothrow @safe this(size_t min, size_t max, size_t actual, string whatYouAttemptedToDo, string file = __FILE__, size_t line = __LINE__)
	{
		version (unittest)
		{
			assert(min <= max);
		}

		version (unittest)
		{
			assert(actual < min || actual > max);
		}

		this.min = min;
		this.max = max;
		this.actual = actual;
		super("This exception was thrown because you attempted to decode an ASN.1 " ~ "element whose value was encoded on too few or too many bytes. The minimum " ~ "number of acceptable bytes is " ~ text(min) ~ " and the maximum " ~ "number of acceptable bytes is " ~ text(max) ~ ", but what you tried " ~ "to decode was " ~ text(actual) ~ " bytes in length. This exception " ~ "was thrown when you were trying to " ~ whatYouAttemptedToDo ~ ".", file, line);
	}
}
public alias ASN1ValueOverflowException = AbstractSyntaxNotation1ValueOverflowException;
public class AbstractSyntaxNotation1ValueOverflowException : ASN1ValueException
{
	mixin basicExceptionCtors!();
}
public alias ASN1ValuePaddingException = AbstractSyntaxNotation1ValuePaddingException;
public class AbstractSyntaxNotation1ValuePaddingException : ASN1ValueException
{
	mixin basicExceptionCtors!();
}
public alias ASN1ValueCharactersException = AbstractSyntaxNotation1ValueCharactersException;
public class AbstractSyntaxNotation1ValueCharactersException : ASN1ValueException
{
	immutable dchar offendingCharacter;
	public pure @safe this(string descriptionOfPermittedCharacters, dchar offendingCharacter, string typeName, string file = __FILE__, size_t line = __LINE__)
	{
		this.offendingCharacter = offendingCharacter;
		super("This exception was thrown because you attempted to encode or " ~ "decode an ASN.1 " ~ typeName ~ " that contained a character " ~ "that is not permitted for that type.\x0a" ~ "The permitted characters are: " ~ descriptionOfPermittedCharacters ~ "\x0a" ~ "The code-point representation of the offending character is: " ~ text(cast(uint)offendingCharacter), file, line);
	}
}
public alias ASN1ValueUndefinedException = AbstractSyntaxNotation1ValueUndefinedException;
public class AbstractSyntaxNotation1ValueUndefinedException : ASN1ValueException
{
	mixin basicExceptionCtors!();
}
public alias ASN1Element = AbstractSyntaxNotation1Element;
abstract public class AbstractSyntaxNotation1Element(Element)
{
	static assert(is(Element : typeof(this)), "Tried to instantiate " ~ (typeof(this)).stringof ~ " with type parameter " ~ Element.stringof);
	protected static ubyte lengthRecursionCount = 0u;
	protected static ubyte valueRecursionCount = 0u;
	static immutable ubyte nestingRecursionLimit = 5u;
	immutable string notWhatYouMeantText = "It is highly likely that what you attempted to decode was not the " ~ "data type that you thought it was. Most likely, one of the following " ~ "scenarios occurred: (1) you did not write this program to the exact " ~ "specification of the protocol, or (2) someone is attempting to hack " ~ "this program (review the HeartBleed bug), or (3) the client sent " ~ "valid data that was just too big to decode. ";
	immutable string forMoreInformationText = "For more information on the specific method or property that originated " ~ "this exception, see the documentation associated with this ASN.1 " ~ "library. For more information on ASN.1's data types in general, see " ~ "the International Telecommunications Union's X.680 specification, " ~ "which can be found at: " ~ "https://www.itu.int/ITU-T/studygroups/com17/languages/X.680-0207.pdf. " ~ "For more information on how those data types are supposed to be " ~ "encoded using Basic Encoding Rules, Canonical Encoding Rules, or " ~ "Distinguished Encoding Rules, see the International " ~ "Telecommunications Union's X.690 specification, which can be found " ~ "at: https://www.itu.int/ITU-T/studygroups/com17/languages/X.690-0207.pdf. ";
	immutable string debugInformationText = "If reviewing the documentation does not help, you may want to run " ~ "the ASN.1 library in debug mode. To do this, compile the source code " ~ "for this library with the `-debug=asn1` flag (if you are compiling " ~ "with `dmd`). This will display information to the console that may " ~ "help you diagnose any issues. ";
	immutable string reportBugsText = "If none of the steps above helped, and you believe that you have " ~ "discovered a bug, please create an issue on the GitHub page's Issues " ~ "section at: https://github.com/JonathanWilbur/asn1-d/issues. ";
	public ASN1TagClass tagClass;
	public ASN1Construction construction;
	public size_t tagNumber;
	public const nothrow @property @safe size_t length()
	{
		return this.value.length;
	}
	public ubyte[] value;
	public const @system void validateTag(ASN1TagClass[] acceptableTagClasses, ASN1Construction acceptableConstruction, size_t[] acceptableTagNumbers, string whatYouAttemptedToDo)
	in
	{
		assert(acceptableTagClasses.length > 0u);
		assert(acceptableTagNumbers.length > 0u);
	}
	do
	{
		if (!canFind(acceptableTagClasses, this.tagClass))
			throw new ASN1TagClassException(acceptableTagClasses, this.tagClass, whatYouAttemptedToDo);
		if (this.construction != acceptableConstruction)
			throw new ASN1ConstructionException(this.construction, whatYouAttemptedToDo);
		if (!canFind(acceptableTagNumbers, this.tagNumber))
			throw new ASN1TagNumberException(acceptableTagNumbers, this.tagNumber, whatYouAttemptedToDo);
	}
	public const @system void validateTag(ASN1TagClass[] acceptableTagClasses, size_t[] acceptableTagNumbers, string whatYouAttemptedToDo)
	in
	{
		assert(acceptableTagClasses.length > 0u);
		assert(acceptableTagNumbers.length > 0u);
	}
	do
	{
		if (!canFind(acceptableTagClasses, this.tagClass))
			throw new ASN1TagClassException(acceptableTagClasses, this.tagClass, whatYouAttemptedToDo);
		if (!canFind(acceptableTagNumbers, this.tagNumber))
			throw new ASN1TagNumberException(acceptableTagNumbers, this.tagNumber, whatYouAttemptedToDo);
	}
	public const nothrow @nogc @property @safe bool isUniversal()
	{
		return this.tagClass == ASN1TagClass.universal;
	}
	public const nothrow @nogc @property @safe bool isApplication()
	{
		return this.tagClass == ASN1TagClass.application;
	}
	public const nothrow @nogc @property @safe bool isContextSpecific()
	{
		return this.tagClass == ASN1TagClass.contextSpecific;
	}
	public const nothrow @nogc @property @safe bool isPrivate()
	{
		return this.tagClass == ASN1TagClass.privatelyDefined;
	}
	public const nothrow @nogc @property @safe bool isPrimitive()
	{
		return this.construction == ASN1Construction.primitive;
	}
	public const nothrow @nogc @property @safe bool isConstructed()
	{
		return this.construction == ASN1Construction.constructed;
	}
	immutable public enum LengthEncodingPreference : ubyte
	{
		definite,
		indefinite,
	}
	public abstract const @property void endOfContent();
	public abstract const @property bool boolean();
	public abstract @property void boolean(in bool value);
	public abstract const @property T integer(T)() if (isIntegral!T && isSigned!T || is(T == BigInt));
	public abstract @property void integer(T)(in T value) if (isIntegral!T && isSigned!T || is(T == BigInt));
	public abstract const @property bool[] bitString();
	public abstract @property void bitString(in bool[] value);
	public abstract const @property ubyte[] octetString();
	public abstract @property void octetString(in ubyte[] value);
	public abstract const @property void nill();
	public alias oid = objectIdentifier;
	public alias objectID = objectIdentifier;
	public abstract const @property OID objectIdentifier();
	public abstract @property void objectIdentifier(in OID value);
	public abstract const @property string objectDescriptor();
	public abstract @property void objectDescriptor(in string value);
	public abstract deprecated const @property External external();
	public abstract deprecated @property void external(in External value);
	public abstract const @property T realNumber(T)() if (isFloatingPoint!T);
	public abstract @property void realNumber(T)(in T value) if (isFloatingPoint!T);
	public abstract const @property T enumerated(T)() if (isIntegral!T && isSigned!T);
	public abstract @property void enumerated(T)(in T value) if (isIntegral!T && isSigned!T);
	public alias embeddedPDV = embeddedPresentationDataValue;
	public abstract const @property EmbeddedPDV embeddedPresentationDataValue();
	public abstract @property void embeddedPresentationDataValue(in EmbeddedPDV value);
	public alias utf8String = unicodeTransformationFormat8String;
	public abstract const @property string unicodeTransformationFormat8String();
	public abstract @property void unicodeTransformationFormat8String(in string value);
	public alias roid = relativeObjectIdentifier;
	public alias relativeOID = relativeObjectIdentifier;
	public abstract const @property OIDNode[] relativeObjectIdentifier();
	public abstract @property void relativeObjectIdentifier(in OIDNode[] value);
	public abstract const @property Element[] sequence();
	public abstract @property void sequence(in Element[] value);
	public abstract const @property Element[] set();
	public abstract @property void set(in Element[] value);
	public abstract const @property string numericString();
	public abstract @property void numericString(in string value);
	public abstract const @property string printableString();
	public abstract @property void printableString(in string value);
	public alias t61String = teletexString;
	public abstract const @property ubyte[] teletexString();
	public abstract @property void teletexString(in ubyte[] value);
	public abstract const @property ubyte[] videotexString();
	public abstract @property void videotexString(in ubyte[] value);
	public alias ia5String = internationalAlphabetNumber5String;
	public abstract const @property string internationalAlphabetNumber5String();
	public abstract @property void internationalAlphabetNumber5String(in string value);
	public alias utc = coordinatedUniversalTime;
	public alias utcTime = coordinatedUniversalTime;
	public abstract const @property DateTime coordinatedUniversalTime();
	public abstract @property void coordinatedUniversalTime(in DateTime value);
	public abstract const @property DateTime generalizedTime();
	public abstract @property void generalizedTime(in DateTime value);
	public abstract deprecated const @property string graphicString();
	public abstract deprecated @property void graphicString(in string value);
	public alias iso646String = visibleString;
	public abstract const @property string visibleString();
	public abstract @property void visibleString(in string value);
	public abstract deprecated @property string generalString();
	public abstract deprecated @property void generalString(in string value);
	public abstract const @property dstring universalString();
	public abstract @property void universalString(in dstring value);
	public abstract const @property CharacterString characterString();
	public abstract @property void characterString(in CharacterString value);
	public alias bmpString = basicMultilingualPlaneString;
	public abstract const @property wstring basicMultilingualPlaneString();
	public abstract @property void basicMultilingualPlaneString(in wstring value);
}
