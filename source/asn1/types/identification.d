module asn1.types.identification;
import std.typecons : Nullable;
import asn1.types.universal.objectidentifier;

///
public
struct ASN1ContextNegotiation
{
    ///
    public ptrdiff_t presentationContextID = 0;
    ///
    public ObjectIdentifier transferSyntax;

    // To use the terms of the pre-1994 EXTERNAL definition:
    public alias directReference = transferSyntax;
    public alias indirectReference = presentationContextID;
}

///
public
struct ASN1Syntaxes
{
    ///
    public ObjectIdentifier abstractSyntax;
    ///
    public ObjectIdentifier transferSyntax;
}

///
public alias ASN1ContextSwitchingTypeID = ASN1ContextSwitchingTypeIdentification;
/**
    This can be used for the creation of Externals, EmbeddedPDVs, and CharacterStrings.
*/
public
struct ASN1ContextSwitchingTypeIdentification
{
    ///
    public Nullable!ASN1Syntaxes syntaxes;
    ///
    public Nullable!ObjectIdentifier syntax;
    ///
    public ptrdiff_t presentationContextID = 0;
    ///
    public Nullable!ASN1ContextNegotiation contextNegotiation;
    ///
    public Nullable!ObjectIdentifier transferSyntax;
    ///
    public bool fixed;

    // To use the terms of the pre-1994 EXTERNAL definition:
    public alias directReference = syntax;
    public alias indirectReference = presentationContextID;
}

/*
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

EXTERNAL ::= [UNIVERSAL 8] IMPLICIT SEQUENCE {
    identification CHOICE {
        syntax OBJECT IDENTIFIER,
        presentation-context-id INTEGER,
        context-negotiation SEQUENCE {
            presentation-context-id INTEGER,
            transfer-syntax OBJECT IDENTIFIER } },
    data-value-descriptor ObjectDescriptor OPTIONAL,
    data-value OCTET STRING }
*/