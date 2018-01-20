module asn1.types.universal.embeddedpdv;
import asn1.types.identification;

/* REVIEW:
    I am going to need some help with this one. I cannot decide
    what the WITH COMPONENTS line means below. I hope it does
    not mean that ANYTHING can be in an EmbeddedPDV.
*/
///
public alias EmbeddedPDV = EmbeddedPresentationDataValue;
/**
    An $(MONO EmbeddedPDV) is a constructed data type, defined in
    the $(LINK https://www.itu.int, International Telecommunications Union)'s
    $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680).

    The specification defines $(MONO EmbeddedPDV) as:

    $(PRE
        EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
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
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }
        (WITH COMPONENTS { ... , data-value-descriptor ABSENT })
    )

    This assumes $(MONO AUTOMATIC TAGS), so all of the $(MONO identification)
    choices will be $(MONO CONTEXT-SPECIFIC) and numbered from 0 to 5.

    The following additional constraints are applied to the abstract syntax
    when using Canonical Encoding Rules or Distinguished Encoding Rules,
    which are also defined in the
    $(LINK https://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
    $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules):

    $(PRE
        EmbeddedPDV ( WITH COMPONENTS {
            ... ,
            identification ( WITH COMPONENTS {
                ... ,
                presentation-context-id ABSENT,
                context-negotiation ABSENT } ) } )
    )

    The stated purpose of the constraints shown above is to restrict the use of
    the $(MONO presentation-context-id), either by itself or within the
    context-negotiation, which makes the following the effective abstract
    syntax of $(MONO EmbeddedPDV) when using Canonical Encoding Rules or
    Distinguished Encoding Rules:

    $(PRE
        EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
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
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }
                ( WITH COMPONENTS {
                    ... ,
                    identification ( WITH COMPONENTS {
                        ... ,
                        presentation-context-id ABSENT,
                        context-negotiation ABSENT } ) } )
    )

    With the constraints applied, the abstract syntax for $(MONO EmbeddedPDV)s encoded
    using Canonical Encoding Rules or Distinguished Encoding Rules becomes:

    $(PRE
        EmbeddedPDV ::= [UNIVERSAL 11] IMPLICIT SEQUENCE {
            identification CHOICE {
                syntaxes SEQUENCE {
                    abstract OBJECT IDENTIFIER,
                    transfer OBJECT IDENTIFIER },
                syntax OBJECT IDENTIFIER,
                transfer-syntax OBJECT IDENTIFIER,
                fixed NULL },
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }
    )
*/
public
struct EmbeddedPresentationDataValue
{
    /**
        A field indicating the the transfer syntax used to indicate the means
        by which the data-value field is encoded. Can also be used to specify
        the abstract syntax of what is encoded.
    */
    public ASN1ContextSwitchingTypeID identification;
    /// The encoded data
    public ubyte[] dataValue;
}