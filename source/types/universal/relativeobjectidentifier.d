module types.universal.relativeobjectidentifier;
import asn1;
import std.traits : isIntegral, isUnsigned;
// import types.types : ASN1UniversalType, ASN1UniversalTypeTag;
import types.oidtype;
import types.universal.objectidentifier;

alias ROIDException = ASN1RelativeObjectIdentifierException;
alias RelativeOIDException = ASN1RelativeObjectIdentifierException;
alias RelativeObjectIDException = ASN1RelativeObjectIdentifierException;
class ASN1RelativeObjectIdentifierException: ASN1Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

alias ROID = RelativeObjectIdentifier;
alias RelativeOID = RelativeObjectIdentifier;
alias RelativeObjectID = RelativeObjectIdentifier;
public class RelativeObjectIdentifier
// : ASN1UniversalType
{
    // override public @property
    // ASN1UniversalTypeTag typeTag()
    // {
    //     return ASN1UniversalTypeTag.relativeOID; // 0x0D
    // }

    private ObjectIdentifier _prefix;
    private OIDNode[] _suffix;

    this(OIDNode[] suffix)
    {
        this._suffix = suffix;
    }

    this(ObjectIdentifier prefix, OIDNode[] suffix)
    {
        /*
            Relative OID's are not supposed to encode either the first or second
            node of the complete OID. Therefore, the prefix OID must be two or
            more nodes in length. We can rule out checking for zero nodes, since
            the ObjectIdentifier constructor would throw an exception upon
            creation of a zero-length OID. So we just check if the prefix is one
            node, and throw an exception if it is.
        */
        if (prefix.length == 1)
            throw new ASN1RelativeObjectIdentifierException
            ("Relative OID cannot encode root arc or arc beneath it.");

        this._prefix = prefix;
        this._suffix = suffix;
    }

    this(T)(T[] oidNumbers ...)
    if (isIntegral!T && isUnsigned!T)
    {
        if (oidNumbers.length == 0u)
            throw new ASN1ObjectIdentifierException
            ("No numbers provided to RelativeObjectIdenifier constructor.");

        foreach (number; oidNumbers)
        {
            this._suffix ~= OIDNode(number);
        }
    }

    public @property
    ObjectIdentifier whole()
    {
        return new ObjectIdentifier(this._prefix.nodes ~ this._suffix);
    }

    public @property
    ulong[] numericArray()
    {
        ulong[] ret;
        foreach(node; this._suffix)
        {
            ret ~= node.number;
        }
        return ret;
    }

    // REVIEW: This is obviously not thorough enough.
    // override public
    // int opCmp(RelativeOID other)
    // {
    //     if (this.numericArray.length > other.numericArray.length)
    //     {
    //         return 1;
    //     }
    //     if (this.numericArray.length < other.numericArray.length)
    //     {
    //         return -1;
    //     }
    //     else
    //     {
    //         return 0;
    //     }
    // }
}
