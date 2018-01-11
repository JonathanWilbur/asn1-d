module types.universal.objectidentifier;
import asn1;
import types.oidtype;
import std.array : appender, Appender;

///
public alias OIDException = ObjectIdentifierException;
///
public alias ObjectIDException = ObjectIdentifierException;
///
public
class ObjectIdentifierException : ASN1Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

///
public alias OID = ObjectIdentifier;
///
public alias ObjectID = ObjectIdentifier;
/**
    A class for Object Identifiers that supports object descriptors and various
    output formatting.
*/
public class ObjectIdentifier
{
    import std.conv : text;

    ///
    static public bool showDescriptors = true;
    ///
    immutable public OIDNode[] nodes;

    /// Returns: the number of nodes in the OID.
    public @property @safe
    size_t length() const
    {
        return this.nodes.length;
    }

    @system
    unittest
    {
        const OID oid = new OID(1, 3, 6, 4, 1);
        assert(oid.length == 5);
    }

    /**
        Constructor for an Object Identifier

        Params:
        $(UL
            $(LI $(D numbers) = an array of unsigned integers representing the Object Identifier)
        )
        Throws:
        $(UL
            $(LI $(D OIDException) if fewer than two numbers are provided, or if the
                first number is not 0, 1, or 2, or if the second number is
                greater than 39)
        )
    */
    public @safe
    this(in size_t[] numbers ...)
    {
        if (numbers.length < 2u)
            throw new OIDException
            ("At least two nodes must be provided to ObjectIdenifier constructor.");

        if (numbers[0] == 0u || numbers[0] == 1u)
        {
            if (numbers[1] > 39u)
                throw new OIDException
                (
                    "Second object identifier node number cannot be greater " ~
                    "than 39 if the first node number is either 0 or 1."
                );
        }
        else if (numbers[0] == 2u)
        {
            if (numbers[1] > 175u)
                throw new OIDException
                (
                    "Second object identifier node number cannot be greater " ~
                    "than 175 if the first node number is 2."
                );
        }
        else
            throw new OIDException
            ("First object identifier node number can only be 0, 1, or 2.");

        OIDNode[] nodes = [];
        foreach (number; numbers)
        {
            nodes ~= OIDNode(number);
        }

        this.nodes = nodes.idup;
    }


    /**
        Constructor for an Object Identifier

        Throws:
        $(UL
            $(LI $(D OIDException) if fewer than two nodes are provided, or if the
                first node is not 0, 1, or 2, or if the second node is greater
                than 39)
        )
    */
    public @safe
    this(OIDNode[] nodes ...)
    {
        if (nodes.length < 2u)
            throw new OIDException
            ("At least two nodes must be provided to ObjectIdenifier constructor.");

        if (nodes[0].number == 0u || nodes[0].number == 1u)
        {
            if (nodes[1].number > 39u)
                throw new OIDException
                (
                    "Second object identifier node number cannot be greater " ~
                    "than 39 if the first node number is either 0 or 1."
                );
        }
        else if (nodes[0].number == 2u)
        {
            if (nodes[1].number > 175u)
                throw new OIDException
                (
                    "Second object identifier node number cannot be greater " ~
                    "than 175 if the first node number is 2."
                );
        }
        else
            throw new OIDException
            ("First object identifier node number can only be 0, 1, or 2.");

        this.nodes = nodes.idup;
    }

    /**
        Constructor for an Object Identifier

        Params:
        $(UL
            $(LI $(D str) = the dot-delimited form of the object identifier)
        )
        Throws:
        $(UL
            $(LI $(D OIDException) if fewer than two nodes are provided, or if the
                first node is not 0, 1, or 2, or if the second node is greater
                than 39)
        )
    */
    public @safe
    this (in string str)
    {
        import std.array : split;
        import std.conv : to;
        string[] segments = str.split(".");

        if (segments.length < 2u)
            throw new OIDException
            ("At least two nodes must be provided to ObjectIdenifier constructor.");

        size_t[] numbers;
        numbers.length = segments.length;

        for (size_t i = 0u; i < segments.length; i++)
        {
            numbers[i] = segments[i].to!size_t;
        }

        if (numbers[0] == 0u || numbers[0] == 1u)
        {
            if (numbers[1] > 39u)
                throw new OIDException
                (
                    "Second object identifier node number cannot be greater " ~
                    "than 39 if the first node number is either 0 or 1."
                );
        }
        else if (numbers[0] == 2u)
        {
            if (numbers[1] > 175u)
                throw new OIDException
                (
                    "Second object identifier node number cannot be greater " ~
                    "than 175 if the first node number is 2."
                );
        }
        else
            throw new OIDException
            ("First object identifier node number can only be 0, 1, or 2.");

        OIDNode[] nodes = [];
        foreach (number; numbers)
        {
            nodes ~= OIDNode(number);
        }

        this.nodes = nodes.idup;
    }

    @system
    unittest
    {
        assert((new OID("0.0.1.127")).numericArray == [ 0, 0, 1, 127 ]);
        assert((new OID("1.1.256.1")).numericArray == [ 1, 1, 256, 1 ]);
        assert((new OID("2.174.3.1")).numericArray == [ 2, 174, 3, 1 ]);

        // Test an invalid first subidentifier
        assertThrown!OIDException(new OID("3.0.1.1"));

        // Test an invalid second identifier
        assertThrown!OIDException(new OID("0.64.1.1"));
        assertThrown!OIDException(new OID("1.64.1.1"));
        assertThrown!OIDException(new OID("1.178.1.1"));

        // Test terminal zero
        assert((new OID("1.0.1.0")).numericArray == [ 1, 0, 1, 0 ]);

        // Test terminal large number
        assert((new OID("1.0.1.65537")).numericArray == [ 1, 0, 1, 65537 ]);
    }

    ///
    override public @system
    bool opEquals(in Object other) const
    {
        const OID that = cast(OID) other;
        if (that is null) return false;
        if (this.nodes.length != that.nodes.length) return false;
        for (ptrdiff_t i = 0; i < this.nodes.length; i++)
        {
            if (this.nodes[i].number != that.nodes[i].number) return false;
        }
        return true;
    }

    @system
    unittest
    {
        const OID a = new OID(1, 3, 6, 4, 1, 5);
        const OID b = new OID(1, 3, 6, 4, 1, 5);
        assert(a == b);
        const OID c = new OID(1, 3, 6, 4, 1, 6);
        assert(a != c);
        const OID d = new OID(2, 3, 6, 4, 1, 6);
        assert(c != d);
    }

    /**
        Returns: the $(D OIDNode) at the specified index.
        Throws:
            RangeError = if invalid index specified.
    */
    public @safe @nogc nothrow
    OIDNode opIndex(in ptrdiff_t index) const
    {
        return this.nodes[index];
    }

    @system
    unittest
    {
        const OID oid = new OID(1, 3, 7000);
        assert((oid[0].number == 1) && (oid[1].number == 3) && (oid[2].number == 7000));
    }

    /**
        Returns: a range of $(D OIDNode)s from the OID.
        Throws:
            RangeError = if invalid indices are specified.
    */
    public @system @nogc nothrow
    OIDNode[] opSlice(in ptrdiff_t index1, in ptrdiff_t index2) const
    {
        return cast(OIDNode[]) this.nodes[index1 .. index2];
    }

    /// Returns the length of the OID.
    public @safe @nogc nothrow
    size_t opDollar() const
    {
        return this.nodes.length;
    }

    /**
        Returns: The descriptor at the specified index.
        Throws:
        $(UL
            $(LI $(D RangeError) if an invalid index is specified)
        )
    */
    public @safe @nogc nothrow
    string descriptor(in size_t index) const
    {
        return this.nodes[index].descriptor;
    }

    @system
    unittest
    {
        const OID oid = new OID(OIDNode(1, "iso"), OIDNode(3, "registered-org"), OIDNode(4, "dod"));
        assert(oid.descriptor(1) == "registered-org");
        assertThrown!RangeError(oid.descriptor(6));
    }

    ///
    public alias numbers = numericArray;
    /**
        Returns:
            an array of $(D size_t)s representing the dot-delimited sequence of
            integers that constitute the numeric OID.
    */
    public @property @safe nothrow
    size_t[] numericArray() const
    {
        size_t[] ret;
        ret.length = this.nodes.length;
        for (ptrdiff_t i = 0; i < this.nodes.length; i++)
        {
            ret[i] = this.nodes[i].number;
        }
        return ret;
    }

    @system
    unittest
    {
        const OID a = new OID(1, 3, 6, 4, 1, 5);
        assert(a.numericArray == [ 1, 3, 6, 4, 1, 5 ]);
    }

    ///
    public alias asn1Notation = abstractSyntaxNotation1Notation;
    /// Returns: the OID in ASN.1 Notation
    public @property @safe nothrow
    string abstractSyntaxNotation1Notation() const
    {
        Appender!string ret = appender!string();
        ret.put("{");
        foreach(node; this.nodes)
        {
            if (this.showDescriptors && node.descriptor != "")
            {
                ret.put(node.descriptor ~ '(' ~ text(node.number) ~ ") ");
            }
            else
            {
                ret.put(text(node.number) ~ ' ');
            }
        }
        return (ret.data[0 .. $-1] ~ '}');
    }

    @system
    unittest
    {
        OID a = new OID(1, 3, 6, 4, 1, 5);
        a.showDescriptors = true;
        assert(a.asn1Notation == "{1 3 6 4 1 5}");

        OID b = new OID(OIDNode(1, "iso"), OIDNode(3, "registered-org"), OIDNode(4, "dod"));
        b.showDescriptors = true;
        assert(b.asn1Notation == "{iso(1) registered-org(3) dod(4)}");
    }

    /**
        Returns:
            the OID as a dot-delimited string, where all nodes with descriptors
            are represented as descriptors instead of numbers
    */
    public @property @safe nothrow
    string dotNotation() const
    {
        Appender!string ret = appender!string();
        foreach (node; this.nodes)
        {
            if (this.showDescriptors && node.descriptor != "")
            {
                ret.put(node.descriptor);
            }
            else
            {
                ret.put(text(node.number));
            }
            ret.put('.');
        }
        return ret.data[0 .. $-1];
    }

    @system
    unittest
    {
        OID a = new OID(1, 3, 6, 4, 1, 5);
        a.showDescriptors = true;
        assert(a.dotNotation == "1.3.6.4.1.5");

        OID b = new OID(OIDNode(1, "iso"), OIDNode(3, "registered-org"), OIDNode(4, "dod"));
        b.showDescriptors = true;
        assert(b.dotNotation == "iso.registered-org.dod");
    }

    ///
    public alias iriNotation = internationalizedResourceIdentifierNotation;
    ///
    public alias uriNotation = internationalizedResourceIdentifierNotation;
    ///
    public alias uniformResourceIdentifierNotation = internationalizedResourceIdentifierNotation;
    /**
        Returns:
            the OID as a forward-slash-delimited string (as one might expect in
            a URI / IRI path), where all nodes with descriptors are represented
            as descriptors instead of numbers
    */
    public @property @system
    string internationalizedResourceIdentifierNotation() const
    {
        import std.uri : encodeComponent; // @system
        Appender!string ret = appender!string();
        ret.put("/");
        foreach (node; this.nodes)
        {
            if (this.showDescriptors && node.descriptor != "")
            {
                ret.put(encodeComponent(node.descriptor) ~ '/');
            }
            else
            {
                ret.put(text(node.number) ~ '/');
            }
        }
        return ret.data[0 .. $-1];
    }

    @system
    unittest
    {
        OID a = new OID(1, 3, 6, 4, 1, 5);
        a.showDescriptors = true;
        assert(a.uriNotation == "/1/3/6/4/1/5");

        OID b = new OID(OIDNode(1, "iso"), OIDNode(3, "registered-org"), OIDNode(4, "dod"));
        b.showDescriptors = true;
        assert(b.uriNotation == "/iso/registered-org/dod");
    }

    ///
    public alias urnNotation = uniformResourceNameNotation;
    /**
        Returns:
            the OID as a URN, where all nodes of the OID are translated to a
            segment in the URN path, and where all nodes are represented as
            numbers regardless of whether or not they have a descriptor
        See_Also:
            $(LINK2 https://www.ietf.org/rfc/rfc3061.txt, RFC 3061)
    */
    public @property @safe nothrow
    string uniformResourceNameNotation() const
    {
        Appender!string ret = appender!string();
        ret.put("urn:oid:");
        foreach (node; this.nodes)
        {
            ret.put(text(node.number) ~ ':');
        }
        return ret.data[0 .. $-1];
    }

    @system
    unittest
    {
        OID a = new OID(1, 3, 6, 4, 1, 5);
        a.showDescriptors = true;
        assert(a.urnNotation == "urn:oid:1:3:6:4:1:5");

        OID b = new OID(OIDNode(1, "iso"), OIDNode(3, "registered-org"), OIDNode(4, "dod"));
        b.showDescriptors = true;
        assert(b.urnNotation == "urn:oid:1:3:4");
    }

    ///
    override public @property
    string toString()
    {
        return this.dotNotation();
    }

    /**
        An override so that associative arrays can use an $(D OIDNode) as a
        key.
        Returns: A $(D size_t) that represents a hash of the $(D OIDNode)
    */
    override public nothrow @trusted
    size_t toHash() const
    {
        size_t sum;
        foreach (node; this.nodes)
        {
            sum += typeid(node).getHash(cast(const void*) &node);
        }
        return sum;
    }

}