module types.universal.characterstring;
import asn1;
import types.identification;

/**
Page 309
CHARACTER STRING ::= [UNIVERSAL 29] SEQUENCE {
    identification CHOICE {
        syntaxes SEQUENCE {
            abstract OBJECT IDENTIFIER,
            transfer OBJECT IDENTIFIER },
        syntax OBJECT IDENTIFIER,
        presentation-context-id INTEGER,
        context-negotiation SEQUENCE {
            presentation-context-id INTEGER,
            transfer-syntax OBJECT IDENTIFIER },
        transfer-syntax OBJECT IDENTIFIER,
        fixed NULL },
    string-value OCTET STRING }
*/
public
struct CharacterString
{
    public ASN1ContextSwitchingTypeID identification;
    public ubyte[] stringValue;
}