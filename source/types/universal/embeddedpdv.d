module types.universal.embeddedpdv;
import types.identification;

/* REVIEW:
    I am going to need some help with this one. I cannot decide
    what the WITH COMPONENTS line means below. I hope it does
    not mean that ANYTHING can be in an EmbeddedPDV.
*/
///
public alias EmbeddedPDV = EmbeddedPresentationDataValue;
/**
    Page: 215
    If a module includes the clause AUTOMATIC TAGS in its header,
    the components of all its structured types (SEQUENCE, SET or CHOICE)
    are automatically tagged by the compiler starting from 0 by one-increment.
    By default, every component is tagged in the implicit mode except if it
    is a CHOICE type, an open type or a parameter that is a type. This
    tagging mechanism is obviously documented in the ASN.1 standard and,
    as a result, does not depend on the compiler. Hence, the module:

        $(I
            M DEFINITIONS AUTOMATIC TAGS ::=
            BEGIN
                T ::= SEQUENCE { a INTEGER,
                b CHOICE { i INTEGER, n NULL },
                c REAL }
            END
        )

    is equivalent, once applied the automatic tagging, to:

        $(I
            M DEFINITIONS ::=
            BEGIN
            T ::= SEQUENCE {
            a [0] IMPLICIT INTEGER,
            b [1] EXPLICIT CHOICE { i [0] IMPLICIT INTEGER,
                                    n [1] IMPLICIT NULL },
            c [2] IMPLICIT REAL }
            END
        )

        $(I
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

    Note that, the data-value-descriptor field should be absent!
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