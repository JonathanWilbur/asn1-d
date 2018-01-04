module compiler;
public import asn1;

///
public alias ASN1CompilerException = AbstractSyntaxNotation1CompilerException;
/// A generic exception from which any ASN.1 compiler exception should inherit
public
class AbstractSyntaxNotation1CompilerException : ASN1Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}