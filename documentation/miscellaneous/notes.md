# Notes

These are mainly for my use in developing this library, but they might be 
useful for you as well... if you can understand them.

## Encoding of CHOICE

### EXPLICIT

```asn1
CHOICE {
    a [0] INTEGER
    b [1] NULL
    c [2] BOOLEAN
}
```

If you chose [1], your BER-encoding would be:

```d
0b10100001u 0x01 0x05 0x00
```

### IMPLICIT

If you chose [1], your encoding would be

```d
0b10100001u 0x00
```

In other words, a context-specific constructed tag, whose tag number is the 
number of the choice made, wraps the universal type of what is encoded.

Page 209:
"[Context-specific] is therefore the default tagging class if no keyword appears in the tagging square brackets."

Page 211:
"The use of [APPLICATION] is therefore not recommended, all the more since 1994, when the condition on distinct tags for the APPLICATION class was abolished."
"The PRIVATE class tags has not been recommended since 1994."

Review page 215

* Apparently, EXTERNAL is used in Association Control Service Element (ACSE). (ISO 8650-1 / ITU X.227)

## EXTERNAL

### Pre-1994

```asn1
    EXTERNAL  ::=  [UNIVERSAL 8] IMPLICIT SEQUENCE
        {
        direct-reference  OBJECT IDENTIFIER OPTIONAL,
        indirect-reference  INTEGER OPTIONAL,
        data-value-descriptor  ObjectDescriptor  OPTIONAL,
        encoding  CHOICE
                    {single-ASN1-type  [0] ANY,
                    octet-aligned     [1] IMPLICIT OCTET STRING,
                    arbitrary         [2] IMPLICIT BIT STRING}
        }
```

Encodes like so:

- U8 
  - C0 
  - C1 
  - C2 
  - C3
    - C1

### Post-1994

```asn1
    EXTERNAL := [UNIVERSAL 8] IMPLICIT SEQUENCE {
        identification CHOICE {
            syntax OBJECT IDENTIFIER,
            presentation-context-id INTEGER,
            context-negotiation SEQUENCE {
                presentation-context-id INTEGER,
                transfer-syntax OBJECT IDENTIFIER } },
        data-value-descriptor ObjectDescriptor OPTIONAL,
        data-value OCTET STRING }
```
(Remember, assuming AUTOMATIC TAGS):
(Refer to page 217)

[My StackOverflow Question](https://stackoverflow.com/questions/46644279/asn-1-ber-encoding-of-embeddedpdv/46649083)

**The problem is that page 413 seems to conflict with what I am interpreting.**

- X.509 does not use automatic tagging, so of course it uses universal tags for almost everything.

https://wiki.wireshark.org/SampleCaptures#X.400

Here is a real, live encoding of an EXTERNAL, from 
[this packet capture](https://wiki.wireshark.org/SampleCaptures?action=AttachFile&do=view&target=p772-transfer-success.pcap),
when viewed with WireShark, using STANAG 4406 (S4406) decoding.

0000   28 2e 06 02 51 01 02 01 03 a0 25 b0 23 80 01 3f  (...Q.....%.#..?
0010   82 01 00 a3 1b a1 19 14 08 50 65 72 63 69 76 61  .........Perciva
0020   6c 17 0d 30 35 31 30 30 31 31 34 35 31 30 38 5a  l..051001145108Z

28 2e (UNIV CONS EXTERNAL)
    06 02 51 01 (UNIV PRIM OBJECT IDENTIFIER)
    02 01 03 (UNIV PRIM INTEGER)
    a0 25 (CTXT CONS 0) <-- This is the start of an X.228 OSI Reliable Transfer Service packet
        b0 23 (CTXT CONS 16)
            80 01 3f (CTXT PRIM 0)
            82 01 00 (CTXT PRIM 2)
            a3 1b (CTXT CONS 3)
                a1 19 (CTXT CONS 1)
                    14 08 50 65 72 63 69 76 61 6c (UNIV PRIM T61String)
                    17 0d 30 35 31 30 30 31 31 34 35 31 30 38 5a (UNIV PRIM UTCTime)

Decodes to:

user-information: 1 item
    Association-data
        direct-reference: 2.1.1 (basic-encoding)
        indirect-reference: 3
        encoding: single-ASN1-type (0)

And here is an EmbeddedPDV:

0000   30 41 02 01 01 a0 3c 60 3a a1 06 06 04 56 00 01  0A....<`:....V..
0010   06 be 30 28 2e 06 02 51 01 02 01 03 a0 25 b0 23  ..0(...Q.....%.#
0020   80 01 3f 82 01 00 a3 1b a1 19 14 08 50 65 72 63  ..?.........Perc
0030   69 76 61 6c 17 0d 30 35 31 30 30 31 31 34 35 31  ival..0510011451
0040   30 38 5a                                         08Z

30 41 (UNIV CONS SEQUENCE)
    02 01 01 (UNIV PRIM INTEGER)
    a0 3c (CTXT CONS 0)
        60 3a (APPL CONS 0)
            a1 06 (CTXT CONS 1)
                06 04 56 00 01 06 (UNIV PRIM OBJECT IDENTIFIER)
            be 30 (CTXT CONS 30)
                28 2e (UNIV CONS EXTERNAL) <-- This is the start of the EXTERNAL decoded above.
                    06 02 51 01 (UNIV PRIM OBJECT IDENTIFIER)
                    02 01 03 (UNIV PRIM INTEGER)
                    a0 25 (CTXT CONS 0)
                        b0 23 (CTXT CONS 16)
                            80 01 3f (CTXT PRIM 0)
                            82 01 00 (CTXT PRIM 2)
                            a3 1b (CTXT CONS 3)
                                a1 19 (CTXT CONS 1)
                                    14 08 50 65 72 63 69 76 61 6c (UNIV PRIM T61String)
                                    17 0d 30 35 31 30 30 31 31 34 35 31 30 38 5a (UNIV PRIM UTCTime)

Decodes to:

fully-encoded-data: 1 item
    PDV-list
        presentation-context-identifier: 1 (id-as-acse)
        presentation-data-values: single-ASN1-type (0)

ISO 8327-1 OSI Session Protocol = X.225
ISO 8823 OSI Presentation Protocol = X.226

X.690, Section 8.18:

> The encoding of a value of the external type shall be the BER encoding of the 
> following sequence type, assumed to be defined in an environment of EXPLICIT 
> TAGS, with a value as specified in the subclauses below

Sounds like:

- U8
  - C0
    - C2
      - U16
        - C0
            - U2
        - C1
            - U6
  - C1
  - C2

Yet, in X.680, Section 34.5:

> The associated type for value definition and subtyping, assuming an automatic 
> tagging environment, is (with normative comments)

and page 303 of the book:

> (defined in an automatic tagging environment)

and 

> The type EXTERNAL is defined (in an automatic tagging environment)

Page 412:
"To ensure upward compatibility of encodings, values of EXTERNAL type, ..., are encoded as if they conformed to the SEQUENCE type on page 301."

Then, still on page 412:

> the context-specific tags, in particular, which appear before the alternatives 
> of the `encoding` component (of type `CHOICE`) must be encoded but not those
> computed in the 1994 version.

This corroborates page 413, which says that an EXTERNAL is encoded the same way 
that an INSTANCE OF is encoded, which is given by the example:

- U8
  - U6
  - U2
  - U7
  - C0 if ANY, C1 if OCTET STRING, or C2 if BIT STRING


Review page 358:
TYPE-IDENTIFIER

[This could be REALLY useful...](https://stackoverflow.com/questions/31106512/decodingtcap-message-dialogueportion/33656267#33656267)

Unrelated, but read this: https://eng.uber.com/trip-data-squeeze/
And this: https://github.com/Microsoft/bond

## X.509 Certificates

```asn1
Certificate ::= SEQUENCE {
    tbsCertificate TBSCertificate,
    signatureAlgorithm AlgorithmIdentifier,
    signatureValue BIT STRING }
```

```asn1
TBSCertificate ::= SEQUENCE {
    version [0] EXPLICIT Version DEFAULT v1,
    serialNumber CertificateSerialNumber,
    signature AlgorithmIdentifier,
    issuer Name,
    validity Validity,
    subject Name,
    subjectPublicKeyInfo SubjectPublicKeyInfo,
    issuerUniqueID [1] IMPLICIT UniqueIdentifier OPTIONAL,
    subjectUniqueID [2] IMPLICIT UniqueIdentifier OPTIONAL,
    extensions [3] EXPLICIT Extensions OPTIONAL }
```

The reason these ISO / ITU protocols never become dominant is because they are 
proprietary and complex.