module types.oidtype;
import asn1;
import codec : ASN1InvalidValueException;
import std.ascii : isGraphical;

///
public alias OIDNode = ObjectIdentifierNode;
/**
    A struct representing a single node in an OID, which has a mandatory
    number and an optional descriptor.
*/
public
struct ObjectIdentifierNode
{
    immutable public size_t number;
    immutable public string descriptor;

    public
    bool opEquals(const OIDNode other) const
    {
        return (this.number == other.number);
    }

    public
    int opCmp(ref const OIDNode other) const
    {
        return cast(int) (this.number - other.number);
    }

    public @safe @nogc nothrow
    this(in size_t number)
    {
        this.number = number;
        this.descriptor = "";
    }

    ///
    public @system
    this(in size_t number, in string descriptor)
    {
        foreach (character; descriptor)
        {
            if ((!character.isGraphical) && (character != ' '))
            {
                throw new ASN1InvalidValueException
                    ("Object descriptor can only contain graphical characters. '"
                    ~ character ~ "' is not graphical.");
            }
        }
        this.number = number;
        this.descriptor = descriptor;
    }
}