// D import file generated from '.\source\asn1\types\universal\embeddedpdv.d'
module asn1.types.universal.embeddedpdv;
import asn1.types.identification;
public alias EmbeddedPDV = EmbeddedPresentationDataValue;
public struct EmbeddedPresentationDataValue
{
	public ASN1ContextSwitchingTypeID identification;
	public ubyte[] dataValue;
}
