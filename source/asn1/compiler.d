/**
    This library does not actually implement a compiler. This is just for the
    future, in case that changes, or if developers want to create their own
    ASN.1 compilers that implement this library.
*/
module asn1.compiler;
public import asn1.constants;

///
public alias ASN1CompilerException = AbstractSyntaxNotation1CompilerException;
/// A generic exception from which any ASN.1 compiler exception should inherit
public
class AbstractSyntaxNotation1CompilerException : ASN1Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}