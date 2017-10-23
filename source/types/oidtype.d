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

    /// Override for use of the `==` operand.
    public
    bool opEquals(const OIDNode other) const
    {
        return (this.number == other.number);
    }

    ///
    @system
    unittest
    {
        OIDNode a = OIDNode(1, "iso");
        OIDNode b = OIDNode(1, "not-iso");
        assert(a == b);
    }

    /// Override for the use of the '>', '<', '<=', and '>=' operands.
    public
    int opCmp(ref const OIDNode other) const
    {
        return cast(int) (this.number - other.number);
    }

    ///
    @system
    unittest
    {
        OIDNode a = OIDNode(1, "iso");
        OIDNode b = OIDNode(2, "even-more-iso");
        assert(b > a);
    }

    /// The simple numeric constructor. Does not throw exceptions.
    public @safe @nogc nothrow
    this(in size_t number)
    {
        this.number = number;
        this.descriptor = "";
    }

    /**
        A constructor that accepts a descriptor string.
        The descriptor string is an ObjectDescriptor, which is defined as:

        $(I ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        GraphicString is just 0x20 to 0x7E, therefore ObjectDescriptor is just
        0x20 to 0x7E.

        Sources:
            $(LINK2 ,
                ASN.1: Communication Between Heterogeneous Systems, pages 175-178)
            $(LINK2 https://en.wikipedia.org/wiki/ISO/IEC_2022, 
                The Wikipedia Page on ISO 2022)
            $(LINK2 https://www.iso.org/standard/22747.html, ISO 2022)

        Returns: a string.
        Throws:
            ASN1InvalidValueException = if the encoded value contains any bytes
                outside of 0x20 to 0x7E.
    */
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

    @system
    unittest
    {
        OIDNode a = OIDNode(1, "Nitro dubs & T-Rix");
        assert(a.descriptor == "Nitro dubs & T-Rix");
        OIDNode b = OIDNode(1, " ");
        assert(b.descriptor == " ");
        OIDNode c = OIDNode(1, "");
        assert(c.descriptor == "");
        assertThrown!ASN1InvalidValueException(OIDNode(1, "\xD7"));
        assertThrown!ASN1InvalidValueException(OIDNode(1, "\t"));
        assertThrown!ASN1InvalidValueException(OIDNode(1, "\r"));
        assertThrown!ASN1InvalidValueException(OIDNode(1, "\n"));
        assertThrown!ASN1InvalidValueException(OIDNode(1, "\b"));
        assertThrown!ASN1InvalidValueException(OIDNode(1, "\v"));
        assertThrown!ASN1InvalidValueException(OIDNode(1, "\f"));
        assertThrown!ASN1InvalidValueException(OIDNode(1, "\0"));
    }
}