module types.oidtype;
import types.universal.objectdescriptor;
import std.traits : isIntegral, isUnsigned;

/**
    A struct representing a single node in an OID, which has a mandatory
    number and an optional descriptor.
*/
public struct OIDNode
{
    /**
        The constructor for OIDNode
        Returns: An OIDNode
    */
    this(T)(T number, ObjectDescriptor descriptor = null)
    if (isIntegral!T && isUnsigned!T)
    {
        this.number = number;
        this.descriptor = descriptor;
    }

    private ulong _number;
    private ObjectDescriptor _descriptor;

    /**
        Gets the number associated with this OIDNode
        Returns: the unsigned long associated with this OIDNode
    */
    @property public ulong number()
    {
        return this._number;
    }
    
    /**
        Sets the number associated with this OIDNode, casting it as a ulong
        in the process
    */
    @property public void number(T)(T number)
    if (isIntegral!T && isUnsigned!T)
    {
        this._number = cast(ulong) number;
    }

    /**
        Gets the descriptor associated with this OIDNode
        Returns: the ObjectDescriptor associated with this OIDNode
    */
    @property public ObjectDescriptor descriptor()
    {
        return this._descriptor;
    }
    
    /**
        Sets the descriptor associated with this OIDNode
    */
    @property public void descriptor(ObjectDescriptor descriptor)
    {
        this._descriptor = descriptor;
    }
}