module types.universal.external;
import asn1;
import types.identification;

/**
Page 303

EXTERNAL := [UNIVERSAL 8] IMPLICIT SEQUENCE {
    identification CHOICE {
        syntax OBJECT IDENTIFIER,
        presentation-context-id INTEGER,
        context-negotiation SEQUENCE {
            presentation-context-id INTEGER,
            transfer-syntax OBJECT IDENTIFIER } },
    data-value-descriptor ObjectDescriptor OPTIONAL,
    data-value OCTET STRING }
*/
public
struct External
{
    public ASN1ContextSwitchingTypeID identification;
    public string dataValueDescriptor; // Made public because validation is done at encoding.
    public ubyte[] dataValue;
}