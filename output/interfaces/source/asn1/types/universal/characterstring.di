// D import file generated from '.\source\asn1\types\universal\characterstring.d'
module asn1.types.universal.characterstring;
import asn1.types.identification;
public struct CharacterString
{
	public ASN1ContextSwitchingTypeID identification;
	public ubyte[] stringValue;
}
