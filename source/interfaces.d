module interfaces;

/**
    An interface for anything that can be converted to and from bytes.
*/
public
interface Byteable
{
    /// Returns: the number of bytes read from the start of the input array
    public size_t fromBytes(in ubyte[]);
    /// Returns: the byte representation of the implementing instance
    public ubyte[] toBytes() const;
}