module types.universal.characterstring;
import types.identification;

/**
    A $(MONO CharacterString), is a constructed data type, defined
    in the $(LINK https://www.itu.int, International Telecommunications Union)'s
        $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

    The specification defines $(MONO CharacterString) as:

    $(PRE
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
    )

    This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
    choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.
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