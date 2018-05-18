// D import file generated from '.\source\asn1\types\universal\objectidentifier.d'
module asn1.types.universal.objectidentifier;
import asn1.constants;
import asn1.types.oidtype;
import std.array : appender, Appender;
public alias OIDException = ObjectIdentifierException;
public alias ObjectIDException = ObjectIdentifierException;
public class ObjectIdentifierException : ASN1Exception
{
	import std.exception : basicExceptionCtors;
	mixin basicExceptionCtors!();
}
public alias OID = ObjectIdentifier;
public alias ObjectID = ObjectIdentifier;
public class ObjectIdentifier
{
	import std.conv : text;
	public static bool showDescriptors = true;
	public immutable OIDNode[] nodes;
	public const @property @safe size_t length();
	public @safe this(in size_t[] numbers...)
	{
		if (numbers.length < 2u)
			throw new OIDException("At least two nodes must be provided to ObjectIdentifier constructor.");
		if (numbers[0] == 0u || numbers[0] == 1u)
		{
			if (numbers[1] > 39u)
				throw new OIDException("Second object identifier node number cannot be greater " ~ "than 39 if the first node number is either 0 or 1.");
		}
		else if (numbers[0] == 2u)
		{
			if (numbers[1] > 175u)
				throw new OIDException("Second object identifier node number cannot be greater " ~ "than 175 if the first node number is 2.");
		}
		else
			throw new OIDException("First object identifier node number can only be 0, 1, or 2.");
		OIDNode[] nodes = [];
		foreach (number; numbers)
		{
			nodes ~= OIDNode(number);
		}
		this.nodes = nodes.idup;
	}
	public @safe this(in OIDNode[] nodes...)
	{
		if (nodes.length < 2u)
			throw new OIDException("At least two nodes must be provided to ObjectIdentifier constructor.");
		if (nodes[0].number == 0u || nodes[0].number == 1u)
		{
			if (nodes[1].number > 39u)
				throw new OIDException("Second object identifier node number cannot be greater " ~ "than 39 if the first node number is either 0 or 1.");
		}
		else if (nodes[0].number == 2u)
		{
			if (nodes[1].number > 175u)
				throw new OIDException("Second object identifier node number cannot be greater " ~ "than 175 if the first node number is 2.");
		}
		else
			throw new OIDException("First object identifier node number can only be 0, 1, or 2.");
		this.nodes = nodes.idup;
	}
	public @safe this(in string str)
	{
		import std.array : split;
		import std.conv : to;
		string[] segments = str.split(".");
		if (segments.length < 2u)
			throw new OIDException("At least two nodes must be provided to ObjectIdentifier constructor.");
		size_t[] numbers;
		numbers.length = segments.length;
		foreach (immutable size_t i, immutable string segment; segments)
		{
			numbers[i] = segment.to!size_t;
		}
		if (numbers[0] == 0u || numbers[0] == 1u)
		{
			if (numbers[1] > 39u)
				throw new OIDException("Second object identifier node number cannot be greater " ~ "than 39 if the first node number is either 0 or 1.");
		}
		else if (numbers[0] == 2u)
		{
			if (numbers[1] > 175u)
				throw new OIDException("Second object identifier node number cannot be greater " ~ "than 175 if the first node number is 2.");
		}
		else
			throw new OIDException("First object identifier node number can only be 0, 1, or 2.");
		OIDNode[] nodes = [];
		foreach (number; numbers)
		{
			nodes ~= OIDNode(number);
		}
		this.nodes = nodes.idup;
	}
	public override const @system bool opEquals(in Object other);
	public const nothrow @nogc @safe OIDNode opIndex(in ptrdiff_t index);
	public const nothrow @nogc @system OIDNode[] opSlice(in ptrdiff_t index1, in ptrdiff_t index2);
	public const nothrow @nogc @safe size_t opDollar();
	public const nothrow @safe string descriptor(in size_t index);
	public alias numbers = numericArray;
	public const nothrow @property @safe size_t[] numericArray();
	public alias asn1Notation = abstractSyntaxNotation1Notation;
	public const nothrow @property @safe string abstractSyntaxNotation1Notation();
	public const nothrow @property @safe string dotNotation();
	public alias iriNotation = internationalizedResourceIdentifierNotation;
	public alias uriNotation = internationalizedResourceIdentifierNotation;
	public alias uniformResourceIdentifierNotation = internationalizedResourceIdentifierNotation;
	public const @property @system string internationalizedResourceIdentifierNotation();
	public alias urnNotation = uniformResourceNameNotation;
	public const nothrow @property @safe string uniformResourceNameNotation();
	public override @property string toString();
	public override const nothrow @trusted size_t toHash();
}
