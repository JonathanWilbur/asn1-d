// D import file generated from '.\source\asn1\types\identification.d'
module asn1.types.identification;
import std.typecons : Nullable;
import asn1.types.universal.objectidentifier;
public struct ASN1ContextNegotiation
{
	public ptrdiff_t presentationContextID = 0;
	public ObjectIdentifier transferSyntax;
	public alias directReference = transferSyntax;
	public alias indirectReference = presentationContextID;
}
public struct ASN1Syntaxes
{
	public ObjectIdentifier abstractSyntax;
	public ObjectIdentifier transferSyntax;
}
public alias ASN1ContextSwitchingTypeID = ASN1ContextSwitchingTypeIdentification;
public struct ASN1ContextSwitchingTypeIdentification
{
	public Nullable!ASN1Syntaxes syntaxes;
	public Nullable!ObjectIdentifier syntax;
	public ptrdiff_t presentationContextID = 0;
	public Nullable!ASN1ContextNegotiation contextNegotiation;
	public Nullable!ObjectIdentifier transferSyntax;
	public bool fixed;
	public alias directReference = syntax;
	public alias indirectReference = presentationContextID;
}
