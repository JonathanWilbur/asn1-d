module types.oidtype;
import asn1;
import codec : ASN1ValueException;
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
    /**
        The unique unsigned integral number associated with a node in the
        object identifier hierarchy.
    */
    immutable public size_t number;
    /**
        The descriptor string is an ObjectDescriptor, which is defined as:

        $(MONO ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        GraphicString is just $(D 0x20) to $(D 0x7E), therefore
        ObjectDescriptor is just $(D 0x20) to $(D 0x7E).

        It is used to describe the object identified by this node.
    */
    immutable public string descriptor;

    /// Override for use of the `==` operand.
    public @safe @nogc nothrow
    bool opEquals(const OIDNode other) const
    {
        return (this.number == other.number);
    }

    ///
    @system
    unittest
    {
        immutable OIDNode a = OIDNode(1, "iso");
        immutable OIDNode b = OIDNode(1, "not-iso");
        assert(a == b);
    }

    /// Override for the use of the '>', '<', '<=', and '>=' operands.
    public @safe @nogc nothrow
    ptrdiff_t opCmp(ref const OIDNode other) const
    {
        return cast(ptrdiff_t) (this.number - other.number);
    }

    /**
        An override so that associative arrays can use an $(D OIDNode) as a
        key.
        Returns: A $(D size_t) that represents a hash of the $(D OIDNode)
    */
    public nothrow @trusted
    size_t toHash() const
    {
        return typeid(this.number).getHash(cast(const void*) &this.number);
    }

    ///
    @system
    unittest
    {
        immutable OIDNode a = OIDNode(1, "iso");
        immutable OIDNode b = OIDNode(2, "even-more-iso");
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

        $(MONO ObjectDescriptor ::= [UNIVERSAL 7] IMPLICIT GraphicString)

        $(MONO GraphicString) is just a string containing only characters between
        and including $(D 0x20) and $(D 0x7E), therefore ObjectDescriptor is just
        $(D 0x20) and $(D 0x7E).

        Throws:
        $(UL
            $(LI $(D ASN1ValueException) if the encoded value contains any bytes
                outside of $(D 0x20) to $(D 0x7E))
        )
    */
    public @system
    this(in size_t number, in string descriptor)
    {
        foreach (immutable character; descriptor)
        {
            if ((!character.isGraphical) && (character != ' '))
            {
                throw new ASN1ValueException
                (
                    "This exception was thrown because you tried to decode " ~
                    "a GraphicString that contained a character that " ~
                    "is not graphical (a character whose ASCII encoding " ~
                    "is outside of the range 0x20 to 0x7E). The offending " ~
                    "character is '" ~ character ~ "'. " ~
                    "For more information on Object Identifiers, read the " ~
                    "International Telecommunications Union's X.660 specification, " ~
                    "which can be found at " ~
                    "http://www.itu.int/rec/T-REC-X.660-201107-I/en. " ~
                    "If you believe that you have " ~
                    "discovered a bug, please create an issue on the GitHub page's Issues " ~
                    "section at: https://github.com/JonathanWilbur/asn1-d/issues. "
                );
            }
        }
        this.number = number;
        this.descriptor = descriptor;
    }

    @system
    unittest
    {
        immutable OIDNode a = OIDNode(1, "Nitro dubs & T-Rix");
        assert(a.descriptor == "Nitro dubs & T-Rix");
        immutable OIDNode b = OIDNode(1, " ");
        assert(b.descriptor == " ");
        immutable OIDNode c = OIDNode(1, "");
        assert(c.descriptor == "");
        assertThrown!ASN1ValueException(OIDNode(1, "\xD7"));
        assertThrown!ASN1ValueException(OIDNode(1, "\t"));
        assertThrown!ASN1ValueException(OIDNode(1, "\r"));
        assertThrown!ASN1ValueException(OIDNode(1, "\n"));
        assertThrown!ASN1ValueException(OIDNode(1, "\b"));
        assertThrown!ASN1ValueException(OIDNode(1, "\v"));
        assertThrown!ASN1ValueException(OIDNode(1, "\f"));
        assertThrown!ASN1ValueException(OIDNode(1, "\0"));
    }
}