// D import file generated from '.\source\asn1\types\oidtype.d'
module asn1.types.oidtype;
import asn1.codec : ASN1ValueException;
import std.ascii : isGraphical;
import std.exception : assertThrown;
public alias OIDNode = ObjectIdentifierNode;
public struct ObjectIdentifierNode
{
	public size_t number;
	private string _descriptor;
	public const pure nothrow @property @safe string descriptor();
	public pure @property @safe void descriptor(string value);
	public const pure nothrow @nogc @safe bool opEquals(const OIDNode other);
	public const pure nothrow @nogc @safe ptrdiff_t opCmp(ref OIDNode other);
	public const nothrow @trusted size_t toHash();
	public pure @safe this(in size_t number, in string descriptor = "")
	{
		this.number = number;
		this.descriptor = descriptor;
	}
}
