// D import file generated from '.\source\asn1\interfaces.d'
module asn1.interfaces;
public interface Byteable
{
	public size_t fromBytes(in ubyte[]);
	public const ubyte[] toBytes();
}
