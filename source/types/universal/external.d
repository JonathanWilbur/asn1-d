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
    private string _dataValueDescriptor;
    public ubyte[] dataValue;

    public @property
    string dataValueDescriptor()
    {
        return this._dataValueDescriptor;
    }

    public @property
    void dataValueDescriptor(string value)
    {
        // FIXME: Add validation! You need to create a new Exception type.
        // import std.ascii : isGraphical;
        // foreach (character; value)
        // {
        //     if (!character.isGraphical)
        //     {
        //         throw new ASN1ObjectDescriptorException(
        //             "Object descriptor can only contain graphical characters. '"
        //             ~ character ~ "' is not graphical.");
        //     }
        // }
        this._dataValueDescriptor = value;
    }
}