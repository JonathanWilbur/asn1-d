// D import file generated from '.\source\asn1\compiler.d'
module asn1.compiler;
public import asn1.constants;
public alias ASN1CompilerException = AbstractSyntaxNotation1CompilerException;
public class AbstractSyntaxNotation1CompilerException : ASN1Exception
{
	import std.exception : basicExceptionCtors;
	mixin basicExceptionCtors!();
}
