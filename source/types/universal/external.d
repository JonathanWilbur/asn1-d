module types.universal.external;
import types.identification;

/**
    According to the
    $(LINK http://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
    $(LINK https://www.itu.int/rec/T-REC-X.680/en, X.680 - Abstract Syntax Notation One (ASN.1)),
    the abstract definition for an $(MONO EXTERNAL), after removing the comments in the
    specification, is as follows:

    $(PRE
        EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
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
                        syntaxes ABSENT,
                        transfer-syntax ABSENT,
                        fixed ABSENT } ) } )
    )

    Note that the abstract syntax resembles that of $(MONO EmbeddedPDV) and
    $(MONO CharacterString), except with a $(MONO WITH COMPONENTS) constraint that removes some
    of our choices of $(MONO identification).
    As can be seen on page 303 of Olivier Dubuisson's
    $(I $(LINK http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF,
        ASN.1: Communication Between Heterogeneous Systems)),
    after applying the $(MONO WITH COMPONENTS) constraint, our reduced syntax becomes:

    $(PRE
        EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
            identification CHOICE {
                syntax OBJECT IDENTIFIER,
                presentation-context-id INTEGER,
                context-negotiation SEQUENCE {
                    presentation-context-id INTEGER,
                    transfer-syntax OBJECT IDENTIFIER } },
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }
    )

    But, according to the
    $(LINK http://www.itu.int/en/pages/default.aspx, International Telecommunications Union)'s
    $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules),
    section 8.18, when encoded using Basic Encoding Rules (BER), is encoded as
    follows, for compatibility reasons:

    $(PRE
        EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
            direct-reference  OBJECT IDENTIFIER OPTIONAL,
            indirect-reference  INTEGER OPTIONAL,
            data-value-descriptor  ObjectDescriptor  OPTIONAL,
            encoding  CHOICE {
                single-ASN1-type  [0] ANY,
                octet-aligned     [1] IMPLICIT OCTET STRING,
                arbitrary         [2] IMPLICIT BIT STRING } }
    )

    The definition above is the pre-1994 definition of $(MONO EXTERNAL). The $(MONO syntax)
    field of the post-1994 definition maps to the $(MONO direct-reference) field of
    the pre-1994 definition. The $(MONO presentation-context-id) field of the post-1994
    definition maps to the $(MONO indirect-reference) field of the pre-1994 definition.
    If $(MONO context-negotiation) is used, per the abstract syntax, then the
    $(MONO presentation-context-id) field of the $(MONO context-negotiation) $(MONO SEQUENCE) in the
    post-1994 definition maps to the $(MONO indirect-reference) field of the pre-1994
    definition, and the $(MONO transfer-syntax) field of the $(MONO context-negotiation)
    $(MONO SEQUENCE) maps to the $(MONO direct-reference) field of the pre-1994 definition.

    The following additional constraints are applied to the abstract syntax
    when using Canonical Encoding Rules or Distinguished Encoding Rules,
    which are also defined in the
    $(LINK http://www.itu.int/en/pages/default.aspx,
    International Telecommunications Union)'s
    $(LINK http://www.itu.int/rec/T-REC-X.690/en, X.690 - ASN.1 encoding rules):

    $(PRE
        EXTERNAL ( WITH COMPONENTS {
            ... ,
            identification ( WITH COMPONENTS {
                ... ,
                presentation-context-id ABSENT,
                context-negotiation ABSENT } ) } )
    )

    The stated purpose of the constraints shown above is to restrict the use of
    the $(MONO presentation-context-id), either by itself or within the
    $(MONO context-negotiation), which makes the following the effective abstract
    syntax of $(MONO EXTERNAL) when using Canonical Encoding Rules or
    Distinguished Encoding Rules:

    $(PRE
        EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
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
                        syntaxes ABSENT,
                        presentation-context-id ABSENT,
                        context-negotiation ABSENT,
                        transfer-syntax ABSENT,
                        fixed ABSENT } ) } )
    )

    With the constraints applied, the abstract syntax for $(MONO EXTERNAL)s encoded
    using Canonical Encoding Rules or Distinguished Encoding Rules becomes:

    $(PRE
        EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
            identification CHOICE {
                syntax OBJECT IDENTIFIER },
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }
    )

    Upon removing the $(MONO CHOICE) tag (since you have no choice but to use syntax
    at this point), the encoding definition when using
    Canonical Encoding Rules or Distinguished Encoding Rules:

    $(PRE
        EXTERNAL ::= [UNIVERSAL 8] SEQUENCE {
            syntax OBJECT IDENTIFIER,
            data-value-descriptor ObjectDescriptor OPTIONAL,
            data-value OCTET STRING }
    )
*/
public
struct External
{
    /**
        A field indicating the the transfer syntax used to indicate the means
        by which the data-value field is encoded. Can also be used to specify
        the abstract syntax of what is encoded.
    */
    public ASN1ContextSwitchingTypeID identification;
    /// An optional field used to describe the encoded data.
    public string dataValueDescriptor; // Made public because validation is done at encoding.
    /// The encoded data
    public ubyte[] dataValue;
    /**
        A field that exists only to determine the developer's choice of
        encoding used, per the pre-1994 definition of EXTERNAL.

        octet-aligned is a sensible default, since it is the most lax of the
        three choices.
    */
    ASN1ExternalEncodingChoice encoding = ASN1ExternalEncodingChoice.octetAligned;
}

///
public alias ASN1ExternalEncodingChoice = AbstractSyntaxNotation1ExternalEncodingChoice;
/**
    The CHOICE of encoding used for the encoding of a pre-1994 EXTERNAL,
    as used by the Basic Encoding Rules, Canonical Encoding Rules, or
    Distinguished Encoding Rules.
*/
public
enum AbstractSyntaxNotation1ExternalEncodingChoice : ubyte
{
    /// single-ASN1-type [0] ABSTRACT-SYNTAX.&Type
    singleASN1Type = singleAbstractSyntaxNotation1Type,
    /// single-ASN1-type [0] ABSTRACT-SYNTAX.&Type
    singleAbstractSyntaxNotation1Type = 0x00u,
    /// octet-aligned [1] IMPLICIT OCTET STRING
    octetAligned = 0x01u,
    /// arbitrary [2] IMPLICIT BIT STRING
    arbitrary = 0x02u
}
