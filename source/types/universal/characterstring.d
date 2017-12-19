module types.universal.characterstring;
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
    /**
        A field indicating the the transfer syntax used to indicate the means 
        by which the string-value field is encoded. Can also be used to specify
        the abstract syntax of what is encoded.
    */
    public ASN1ContextSwitchingTypeID identification;
    /// The encoded data
    public ubyte[] stringValue;
}