module types.universal.objectidentifier;
import asn1;
// import types.types : ASN1UniversalType, ASN1UniversalTypeTag;
import types.oidtype;
import types.universal.objectdescriptor;
import std.traits : isIntegral, isUnsigned;

alias ASN1OIDException = ASN1ObjectIdentifierException;
alias ASN1ObjectIDException = ASN1ObjectIdentifierException;
class ASN1ObjectIdentifierException : ASN1Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

/**
    A class for Object Identifiers, that supports object descriptors and various
    output formatting.
*/
public alias OID = ObjectIdentifier;
public alias ObjectID = ObjectIdentifier;
public class ObjectIdentifier
{

    import std.conv : text;
    import std.algorithm.searching : canFind;
    import std.algorithm.comparison : min;

    // override public @property
    // ASN1UniversalTypeTag typeTag()
    // {
    //     return ASN1UniversalTypeTag.objectidentifier; // 0x06
    // }

    public bool showDescriptors = true; //TODO
    public size_t nodeLengthLimit = 64; //TODO

    private OIDNode[] _nodes = [];
    @property public OIDNode[] nodes()
    {
        return this._nodes;
    }

    /**
        Constructor for OID.
        Params:
            oidNumbers = An array of any integers of any unsigned integral type
                representing the sequence of node numbers that constitute the
                Object Identifier
        Returns: An ObjectIdentifier with no descriptors.
        Throws:
            ASN1ObjectIdentifierException if no numbers are provided
            ASN1ObjectIdentifierException if too many numbers are provided
            ASN1ObjectIdentifierException if the first number is not 0, 1, or 2
            ASN1ObjectIdentifierException if the second number is greater than 39
    */
    this(T)(T[] oidNumbers ...)
    if (isIntegral!T && isUnsigned!T)
    {
        if (oidNumbers.length == 0u)
            throw new ASN1ObjectIdentifierException
            ("No numbers provided to ObjectIdenifier constructor.");

        if (oidNumbers.length > this.nodeLengthLimit)
            throw new ASN1ObjectIdentifierException
            ("Object identifier's length exceeded the configured length limit.");

        if (!([0u,1u,2u].canFind(oidNumbers[0])))
            throw new ASN1ObjectIdentifierException
            ("First object identifier node number can only be 0, 1, or 2.");

        if (oidNumbers.length > 1u && oidNumbers[1] > 39u)
            throw new ASN1ObjectIdentifierException
            ("Second object identifier node number cannot be greater than 39.");

        foreach (number; oidNumbers)
        {
            this._nodes ~= OIDNode(number);
        }
    }

    /**
        Constructor for OID
        Params:
            oidnodes = An array of OIDNodes
        Returns: An OID object
        Throws:
            OIDLengthException if number of oidnodes (length of OID) is negative
            or greater than 64
    */
    this(OIDNode[] nodes ...)
    {
        if (nodes.length == 0)
            throw new ASN1ObjectIdentifierException
            ("No nodes provided to ObjectIdenifier constructor.");

        if (nodes.length > this.nodeLengthLimit)
            throw new ASN1ObjectIdentifierException
            ("Object identifier's length exceeded the configured length limit.");

        if (!([0,1,2].canFind(nodes[0].number)))
            throw new ASN1ObjectIdentifierException
            ("First object identifier node number can only be 0, 1, or 2.");

        if (nodes.length > 1 && nodes[1].number > 39)
            throw new ASN1ObjectIdentifierException
            ("Second object identifier node number cannot be greater than 39.");

        this._nodes = nodes;
    }

    // //NOTE: This ignores the descriptors applied to each node.
    // override bool opEquals(ObjectIdentifier oid)
    // {
    //     if (this._nodes.length != oid.length) return false;
    //     ulong[] oidNumbers = oid.numericArray();
    //     for (int i; i < oid.length; i++)
    //     {
    //         if (this._nodes[i].number != oidNumbers[i]) return false;
    //     }
    //     return true;
    // }
    //
    // //NOTE: This ignores the descriptors applied to each node.
    // override bool opEquals(T)(T[] numbers)
    // if (isIntegral!T && isUnsigned!T)
    // {
    //     if (this._nodes.length != numbers.length) return false;
    //     for (int i; i < numbers.length; i++)
    //     {
    //         if (this._nodes[i].number != numbers[i]) return false;
    //     }
    //     return true;
    // }
    //
    // //REVIEW: I am not sure what the return value is supposed to mean.
    // //NOTE: This ignores the descriptors applied to each node.
    // override int opCmp(ObjectIdentifier oid)
    // {
    //     ulong[] oidNumbers = oid.numericArray();
    //     size_t comparableLength = min(this._nodes.length, oid.length);
    //     for (int i; i < comparableLength; i++)
    //     {
    //         if (this._nodes[i].number < oidNumbers[i]) return -1;
    //         if (this._nodes[i].number > oidNumbers[i]) return 1;
    //     }
    //     return 0;
    // }
    //
    // //REVIEW: I am not sure what the return value is supposed to mean.
    // //NOTE: This ignores the descriptors applied to each node.
    // override int opCmp(T)(T[] numbers)
    // if (isIntegral!T && isUnsigned!T)
    // {
    //     size_t comparableLength = min(this._nodes.length, numbers.length);
    //     for (int i; i < comparableLength; i++)
    //     {
    //         if (this._nodes[i].number < numbers[i]) return -1;
    //         if (this._nodes[i].number > numbers[i]) return 1;
    //     }
    //     return 0;
    // }

    void opIndexAssign(T)(T value, size_t index)
    if (isIntegral!T && isUnsigned!T)
    in
    {
        assert(index < this._nodes.length); // Also checks that length != 0
    }
    body
    {
        if (index == 0)
        {
            if ([0,1,2].canFind(value))
            {
                this._nodes[0] = OIDNode(value);
            }
            else
            {
                throw new ASN1ObjectIdentifierException
                ("First object identifier node number can only be 0, 1, or 2.");
            }
        }
        else if (index == 1)
        {
            if (value < 40)
            {
                this._nodes[1] = OIDNode(value);
            }
            else
            {
                throw new ASN1ObjectIdentifierException
                ("Second object identifier node number cannot be greater than 39.");
            }
        }
        else
        {
            this._nodes[index] = OIDNode(value);
        }
    }

    void opIndexAssign(ObjectDescriptor desc, size_t index)
    in
    {
        assert(index < this._nodes.length); // Also checks that length != 0
    }
    body
    {
        this._nodes[index].descriptor = desc;
    }

    void opOpAssign(string op)(OIDNode[] ons ...)
    in
    {
        assert(this._nodes.length >= 1);
    }
    body
    {
        if (ons.length == 0) return;

        if (ons.length + this._nodes.length > this.nodeLengthLimit)
            throw new ASN1ObjectIdentifierException
            ("Object identifier's length exceeded the configured length limit.");

        static if (op == "~")
        {
            if (this._nodes.length == 1)
            {
                if (ons[0].number < 40)
                {
                    this._nodes ~= ons;
                }
                else
                {
                    throw new ASN1ObjectIdentifierException
                    ("Second object identifier node number cannot be greater than 39.");
                }
            }
            else
            {
                this._nodes ~= ons;
            }
        }
        else static assert(0, "Operator "~op~" not implemented");
    }

    public OIDNode opIndex(size_t index)
    {
        return this._nodes[index];
    }

    public OIDNode[] opSlice(size_t index1, size_t index2)
    {
        return this._nodes[index1 .. index2];
    }

    // public size_t opDollar(size_t argumentPosition)()
    // {
    //     static if (pos == 0)
    //         return width;
    //     else
    //         return height;
    // }

    public size_t opDollar()
    {
        return this._nodes.length;
    }

    /**
        Returns: The descriptor at the specified index.
    */
    public ObjectDescriptor descriptor(size_t index)
    {
        return this._nodes[index].descriptor;
    }

    /**
        Supplies a node descriptor for a node at a specified index in the OID
        Params:
            index = an integer specifying an index of the node you wish to change
            descriptor = the actual text that you want associated with a node.
                This must be composed of only
                $(LINK2 https://en.wikipedia.org/wiki/Graphic_character, Graphic Characters).
        Throws:
            RangeError if the node addressed is non-existent or negative.
            OIDDescriptorException if the descriptor is too long or non graphical.
    */
    public void descriptor(T)(T index, ObjectDescriptor descriptor)
    if (isIntegral!T && isUnsigned!T)
    {
        this._nodes[index].descriptor = descriptor;
    }

    /**
        Returns: an array of all descriptors in order
    */
    @property public ObjectDescriptor[] descriptors()
    {
        ObjectDescriptor[] ret;
        foreach(node; this._nodes)
        {
            ret ~= node.descriptor;
        }
        return ret;
    }

    /**
        Supplies multiple descriptors for nodes in the OID
        Params:
            descriptors = descriptors for each node in order
        Throws:
            ASN1ObjectIdentifierException if too many descriptors provided.
    */
    @property public void descriptors(ObjectDescriptor[] descriptors)
    {
        if (descriptors.length > this._nodes.length)
            throw new ASN1ObjectIdentifierException("Too many descriptors.");

        for (int i = 0; i < descriptors.length; i++)
        {
            this._nodes[i].descriptor = descriptors[i];
        }
    }

    /**
        Returns:
            an array of ulongs representing the dot-delimited sequence of
            integers that constitute the numeric OID
    */
    @property public ulong[] numericArray()
    {
        ulong[] ret;
        foreach(node; this._nodes)
        {
            ret ~= node.number;
        }
        return ret;
    }

    /**
        Returns: the OID in ASN.1 Notation
    */
    @property public string asn1Notation()
    {
        string ret = "{";
        foreach(node; this._nodes)
        {
            if (this.showDescriptors && node.descriptor.toString() != "")
            {
                ret ~= (node.descriptor.toString() ~ '(' ~ text(node.number) ~ ") ");
            }
            else
            {
                ret ~= (text(node.number) ~ ' ');
            }
        }
        return (ret[0 .. $-1] ~ '}');
    }

    /**
        Returns:
            the OID as a dot-delimited string, where all nodes with descriptors
            are represented as descriptors instead of numbers
    */
    @property public string dotNotation()
    {
        string ret;
        foreach (node; this._nodes)
        {
            if (this.showDescriptors && node.descriptor.toString() != "")
            {
                ret ~= node.descriptor.toString();
            }
            else
            {
                ret ~= text(node.number);
            }
            ret ~= '.';
        }
        return ret[0 .. $-1];
    }

    /**
        Returns:
            the OID as a forward-slash-delimited string (as one might expect in
            a URI / IRI path), where all nodes with descriptors are represented
            as descriptors instead of numbers
    */
    @property public string iriNotation()
    {
        import std.uri : encodeComponent;
        string ret = "/";
        foreach (node; this._nodes)
        {
            if (this.showDescriptors && node.descriptor.toString() != "")
            {
                ret ~= (encodeComponent(node.descriptor.toString()) ~ '/');
            }
            else
            {
                ret ~= (text(node.number) ~ '/');
            }
        }
        return ret[0 .. $-1];
    }

    /**
        Returns:
            the OID as a URN, where all nodes of the OID are translated to a
            segment in the URN path, and where all nodes are represented as
            numbers regardless of whether or not they have a descriptor
        See_Also:
            $(LINK2 https://www.ietf.org/rfc/rfc3061.txt, RFC 3061)
    */
    @property public string urnNotation()
    {
        string ret = "urn:oid:";
        foreach (node; this._nodes)
        {
            ret ~= (text(node.number) ~ ':');
        }
        return ret[0 .. $-1];
    }

    /**
        Returns: the number of nodes in the OID.
    */
    @property public size_t length()
    {
        return this._nodes.length;
    }

    //NOTE: Having trouble compiling with this._nodes[#].number for some reason.
    // invariant
    // {
    //     assert(this._nodes.length > 0, "OID length is zero!");
    //     assert([0,1,2].canFind((this.nodes)[0].number), "OID node #1 is not 0, 1, or 2!");
    //     if (this._nodes.length > 1)
    //         assert(this._nodes[1].number < 40, "OID node #2 is greater than 39!");
    // }

}