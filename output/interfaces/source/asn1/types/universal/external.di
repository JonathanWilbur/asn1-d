// D import file generated from '.\source\asn1\types\universal\external.d'
module asn1.types.universal.external;
import asn1.types.identification;
public struct External
{
	public ASN1ContextSwitchingTypeID identification;
	public string dataValueDescriptor;
	public ubyte[] dataValue;
	ASN1ExternalEncodingChoice encoding = ASN1ExternalEncodingChoice.octetAligned;
}
public alias ASN1ExternalEncodingChoice = AbstractSyntaxNotation1ExternalEncodingChoice;
public enum AbstractSyntaxNotation1ExternalEncodingChoice : ubyte
{
	singleASN1Type = singleAbstractSyntaxNotation1Type,
	singleAbstractSyntaxNotation1Type = 0u,
	octetAligned = 1u,
	arbitrary = 2u,
}
