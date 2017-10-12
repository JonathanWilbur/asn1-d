module types.identification;
import std.typecons : Nullable;
import types.universal.objectidentifier;

///
public
struct ASN1ContextNegotiation
{
    public long presentationContextID = 0L;
    public ObjectIdentifier transferSyntax;
}

///
public
struct ASN1ContextSwitchingTypeSyntaxes
{
    public ObjectIdentifier abstractSyntax;
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
    public Nullable!ASN1ContextSwitchingTypeSyntaxes syntaxes;
    public Nullable!ObjectIdentifier syntax;
    public long presentationContextID = 0L;
    public Nullable!ASN1ContextNegotiation contextNegotiation;
    public Nullable!ObjectIdentifier transferSyntax;
    public bool fixed;
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