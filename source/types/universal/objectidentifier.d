module types.universal.objectidentifier;
import asn1;
import types.oidtype;

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
    A class for Object Identifiers, that supports object descriptors and various
    output formatting.
*/
public class ObjectIdentifier
{
    import std.conv : text;

    static public bool showDescriptors = true;
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
        OID oid = new OID(1, 3, 6, 4, 1);
        assert(oid.length == 5);
    }

    /**
        Constructor for an Object Identifier

        Params:
            numbers = an array of unsigned integer representing the Object Identifier
        Returns: An OID object
        Throws:
            OIDException = if fewer than three numbers are provided, or if the
                first number is not 0, 1, or 2, or if the second number is 
                greater than 39.
    */
    public @system
    this(size_t[] numbers ...)
    {
        if (numbers.length < 3u)
            throw new OIDException
            ("At least three nodes must be provided to ObjectIdenifier constructor.");

        if ((numbers[0] != 0) && (numbers[0] != 1) && (numbers[0] != 2))
            throw new OIDException
            ("First object identifier node number can only be 0, 1, or 2.");

        if (numbers[1] > 39)
            throw new OIDException
            ("Second object identifier node number cannot be greater than 39.");

        Appender!(OIDNode[]) nodes = appender!(OIDNode[]);
        foreach (number; numbers)
        {
            nodes.put(OIDNode(number));
        }

        this.nodes = cast(immutable (OIDNode[])) nodes.data;
    }


    /**
        Constructor for an Object Identifier
        
        Params:
            nodes = An array of OIDNodes
        Returns: An OID object
        Throws:
            OIDException = if fewer than three nodes are provided, or if the
                first node is not 0, 1, or 2, or if the second node is greater
                than 39.
    */
    public @safe
    this(immutable OIDNode[] nodes ...)
    {
        if (nodes.length < 3u)
            throw new OIDException
            ("At least three nodes must be provided to ObjectIdenifier constructor.");

        if ((nodes[0].number != 0) && (nodes[0].number != 1) && (nodes[0].number != 2))
            throw new OIDException
            ("First object identifier node number can only be 0, 1, or 2.");

        if (nodes[1].number > 39)
            throw new OIDException
            ("Second object identifier node number cannot be greater than 39.");

        this.nodes = nodes;
    }

    override public @system
    bool opEquals(Object other) const
    {
        OID that = cast(OID) other;
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
        OID a = new OID(1, 3, 6, 4, 1, 5);
        OID b = new OID(1, 3, 6, 4, 1, 5);
        assert(a == b);
        OID c = new OID(1, 3, 6, 4, 1, 6);
        assert(a != c);
        OID d = new OID(2, 3, 6, 4, 1, 6);
        assert(c != d);
    }

    /**
        Returns: the OIDNode at the specified index.
        Throws:
            RangeError = if invalid index specified.
    */
    public @safe
    OIDNode opIndex(ptrdiff_t index) const
    {
        return this.nodes[index];
    }

    @system
    unittest
    {
        OID oid = new OID(1, 3, 7000);
        assert((oid[0].number == 1) && (oid[1].number == 3) && (oid[2].number == 7000));
    }

    /**
        Returns: a range of OIDNodes from the OID.
        Throws:
            RangeError = if invalid indices are specified.
    */
    public @system
    OIDNode[] opSlice(ptrdiff_t index1, ptrdiff_t index2) const
    {
        return cast(OIDNode[]) this.nodes[index1 .. index2];
    }

    /**
        Returns: the length of the OID.
    */
    public @safe nothrow
    size_t opDollar() const
    {
        return this.nodes.length;
    }

    /**
        Returns: The descriptor at the specified index.
        Throws:
            RangeError = if invalid index specified.
    */
    public @safe
    string descriptor(size_t index) const
    {
        return this.nodes[index].descriptor;
    }

    @system
    unittest
    {
        OID oid = new OID(OIDNode(1, "iso"), OIDNode(3, "registered-org"), OIDNode(4, "dod"));
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
        ulong[] ret;
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
        OID a = new OID(1, 3, 6, 4, 1, 5);
        assert(a.numericArray == [ 1, 3, 6, 4, 1, 5 ]);
    }

    ///
    public alias asn1Notation = abstractSyntaxNotation1Notation;
    /**
        Returns: the OID in ASN.1 Notation
    */
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

}