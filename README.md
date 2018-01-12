# ASN.1 D Library

* Author: [Jonathan M. Wilbur](http://jonathan.wilbur.space) <[jonathan@wilbur.space](mailto:jonathan@wilbur.space)>
* Copyright Year: 2018
* License: [MIT License](https://mit-license.org/)
* Version: [1.0.0-beta.80](http://semver.org/)

**Expected Version 1.0.0 Release Date: January 12th, 2018**

## What is ASN.1?

ASN.1 stands for *Abstract Syntax Notation*. ASN.1 was first specified in
[X.680 - Abstract Syntax Notation One (ASN.1)](https://www.itu.int/rec/T-REC-X.680/en),
by the [International Telecommunications Union](http://www.itu.int/en/pages/default.aspx).
ASN.1 messages can be encoded in one of several encoding/decoding standards.
It provides a system of types that are extensible, and can presumably describe
every protocol. You can think of it as a protocol for describing other protocols
as well as a family of standards for encoding and decoding said protocols.
It is similar to Google's [Protocol Buffers](https://developers.google.com/protocol-buffers/),
or Sun Microsystems' [External Data Representation (XDR)](https://tools.ietf.org/html/rfc1014).

## Why ASN.1?

ASN.1 is used in, or required by, multiple technologies, including:

* [X.509 Certificates](http://www.itu.int/rec/T-REC-X.509-201610-I/en), used in [SSL/TLS](https://tools.ietf.org/html/rfc5246)
* [Lightweight Directory Access Protocol (LDAP)](https://www.ietf.org/rfc/rfc4511.txt)
* [X.400]()
* [X.500](http://www.itu.int/rec/T-REC-X.500-201610-I/en)
* The [magnetic stripes](https://www.iso.org/standard/43317.html) on credit cards and debit cards
* Microsoft's [Remote Desktop Protocol (RDP)](https://msdn.microsoft.com/en-us/library/mt242409.aspx)
* [Simple Network Management Protocol (SNMP)](https://www.ietf.org/rfc/rfc1157.txt)
* [Common Management Information Protocol (CMIP)](http://www.itu.int/rec/T-REC-X.711/en)
* [Signalling System Number 7 (SS7)](http://www.itu.int/rec/T-REC-Q.700-199303-I/en),
  used to make most phone calls on the Public Switched Telephone Network (PSTN).
* [H.323](http://www.itu.int/rec/T-REC-H.323-200912-I/en) Video conferencing
* Biometrics Protocols:
  * [BioAPI Interworking Protocol (BIP)](https://www.iso.org/standard/43611.html)
  * [Common Biometric Exchange Formats Framework (CBEFF)](http://nvlpubs.nist.gov/nistpubs/Legacy/IR/nistir6529-a.pdf)
  * [Authentication Contexts for Biometrics (ACBio)](https://www.iso.org/standard/41531.html)
* [Computer Supported Telecommunications Applications (CSTA)](https://www.ecma-international.org/activities/Communications/TG11/cstaIII.htm)
* [Dedicated Short Range Communications (SAE J2735)](http://standards.sae.org/j2735_200911/)
* Cellular telephony:
  * [Global System for Mobile Communications (GSM)](http://www.ttfn.net/techno/smartcards/gsm11-11.pdf)
  * [Global Packet Radio Service (GPRS) / Enhanced Data Rates for Global Evolution (EDGE)](http://www.3gpp.org/technologies/keywords-acronyms/102-gprs-edge)
  * [Universal Mobile Telecommunications System (UTMS)](http://www.3gpp.org/DynaReport/25-series.htm)
  * [Long-Term Evolution (LTE)](http://www.3gpp.org/technologies/keywords-acronyms/98-lte)

If you look in the
[`asn1` directory of WireShark's source code](https://github.com/wireshark/wireshark/tree/master/epan/dissectors/asn1),
you'll see all of the protocols that use ASN.1.

## Usage

For each codec in the library, usage entails instantiating the class,
then using that class' properties to get and set the encoded value.
For all classes, the empty constructor creates an `END OF CONTENT`
element. The remaining constructors will be codec-specific.

Here is an example of encoding with Basic Encoding Rules, using the
`BERElement` class.

```d
BERElement el = new BERElement();
el.typeTag = ASN1UniversalType.integer;
el.integer!long = 1433; // Now the data is encoded.
writefln("%(%02X %)", cast(ubyte[]) el); // Writes the encoded bytes to the terminal.
```

... and here is how you would decode that same element:

```d
ubyte[] encodedData = cast(ubyte[]) el;
BERElement el2 = new BERElement(encodedData);
long x = el2.integer!long;
```

## Development

I hope to be done with this library before the end of 2017. When it is
complete, it will contain several codecs, and everything will be unit-tested
and reviewed for security and performance.

### 1.0.0-beta Development

Version 1.0.0-beta was released on November 8th, 2017.

**Expected Version 1.0.0 Release Date: December 31st, 2017**

- [x] Fix licensing (Some parts of this project still say "ISC" instead of "MIT.")
- [x] Find and change integral types to either `size_t` or `ptrdiff_t`
- [x] Use `size_t` and `ptrdiff_t` appropriately for array indices and lengths
- [x] Extract the string constants into either `codec.d`, `asn1.d`, or something else.
- [x] Prohibit leading zeroes in `tagNumber`, per section 8.1.2.4.2, item C, from X.690.
- [x] Perform unit tests on the `tagNumber` encoding
- [x] Check the encoding of `tagNumber` for non-terminating
- [x] Reconcile `BIT STRING` properties among codecs
- [x] Definite Long Length Encoding:
  - BER does not have to encode or decode on the fewest octets
  - CER MUST encode and decode the fewest octets
  - DER MUST encode and decode the fewest octets
- [x] Ensure that length <= 127 is not encoded in long form for CER and DER
- [x] Check for:
  - [x] `TODO`
  - [x] `FIXME`
  - [x] `REVIEW`
- [x] Prohibit leading zeroes in encoding and decoding of `INTEGER` and `ENUMERATED`
- [x] Create ranged unit tests for `INTEGER` and `ENUMERATED`
- [x] Fix OID / ROID
  - [x] Review that un-terminating OID components do not crash program.
  - [x] Throw exception if encoded OID type contains `0x80u` (See Note #1 below.)
  - [x] Permit `OID` to contain arcs under `2` that exceed `39`, but not `175`.
  - [x] Remove dependency on `Appender`
  - [x] Allow `OID`s to be only two nodes long
  - [x] Use the terms 'node', 'component', 'number', and 'subidentifier' consistently
    - X.660 uses the term 'node' and 'arc'
    - X.690 uses the term 'subidentifier'
    - The Dubuisson book uses the term 'arc' and 'node'
    - It sounds like 'arc' refers to the space beneath a 'node'
  - [x] Test string constructor of `OID`
- [x] Improve Context-Switching Types
  - [x] Make them actually work
  - [x] Support the pre-1994 `EXTERNAL`
  - [x] Deprecate `EXTERNAL`
  - [x] Document all of the fields
  - [x] Unittest all variations of `EXTERNAL`'s `encoding`
  - [x] ~~Implement `OBJECT IDENTIFIER` restrictions for `CharacterString`~~ (I can't find documentation of this.)
  - [x] Enforce construction of subcomponents of CSTs
- [x] Add Object Identifier constants from Section 12 of X.690
- [x] Make as much code `const` or `immutable` as possible
- [x] Make `Byteable` interface, and implement it on all codecs
- [x] Add storage classes to `codec` and to its children
- [x] Write unit testing information to terminal
- [x] Code de-duplication
  - [x] ~~Since the `characterString` code is so similar to `embeddedPDV`, could I de-duplicate?~~
  - [x] ~~Break X.690 common functionality into template mixins~~ (See Note #2 below.)
  - [x] De-duplicate decoding code (private `fromBytes()` method called by constructor)
- [x] Configure `.vscode/tasks.json`
- [x] Configure `dub.json`
- [x] Either do something with `valueContainsDoubleNull()` or make it public
- [x] String `ObjectIdentifier` constructor
- [x] Properties for member `type`
  - [x] `typeClass` (Just rename `tagClass`.)
  - [x] `typeConstruction` (Just rename `construction`.)
  - [x] `typeNumber`
- [x] Rename `enum`s in `asn1.d`.
- [x] Command Line Tools
  - [x] Create a template mixin or something to reduce duplication between decoders.
  - [x] `encode-der`
  - [x] `encode-ber`
  - [x] `encode-cer`
  - [x] `decode-der`
  - [x] `decode-ber`
  - [x] `decode-cer`
  - [x] Fix them
  - [x] Catch exceptions and display error message.
- [x] Test that all one-byte elements throw exceptions
- [x] Test an OID with a node with a values 127, 128, and 0.
- [x] Test even more significant mathematical values with `realNumber()`:
  - [x] `sqrt(2)/2`
  - [x] The golden ratio
  - [x] Everything [here](https://en.wikipedia.org/wiki/Mathematical_constant)
  - [x] `max` of every integral type
  - [x] `min` of every integral type
- [x] Test that `.length` > 1000 octetStrings cannot modify their references
- [x] Test really large items
- [x] Encode `INTEGER` of 0 as a single null byte and, decode it as such.
- [x] Fuzz testing to ensure `RangeError` is never thrown. If it is thrown, it means that there are vulnerabilities if compiled with `-boundscheck=off` flag.
  - [x] Fuzz test all possible two-byte combinations
  - [x] Fuzz test all possible three-byte combinations
- [x] Enforce `0` padding bits for DER and CER-encoded `BIT STRING`
- [x] Test a `BIT STRING` with only a first byte
- [x] Fix `REAL`
  - [x] Remove encoding capabilities for anything but base-2.
  - [x] Fix CER and DER base-2 `REAL` must encode the exponent on the fewest octets, and scale = 0.
  - [x] Enforce exponent > 0 when using complicated exponent encoding. (X.690 8.5.6.4.d)
  - [x] Enforce exponent encoding on the fewest possible octets
  - [x] Enforce mantissa > 0. (X.690 8.5.2)
  - [x] Test for odd using a bitmask of 0x01 instead of modulus.
  - [x] Enforce odd mantissa for CER and DER when decoding.
  - [x] Note that you are assuming IEEE 754 Floating Points.
  - [x] Banish the term "significand" to the shadow realm.
  - [x] Change the property's name to `realNumber`.
  - [x] Change the template to accept any type that `isFloatingPoint`.
  - [x] Validate base-10 decoding
  - [x] Remove dependency on `FloatRep` and `DoubleRep`
  - [x] Ensure no overflows on returning a `float`
  - [x] Ensure using base-8 or base-16 cannot be used to overflow
  - [x] Remove `approxEqual` from unit tests, if possible
- [x] Search for `reverse` for potential optimizations
- [x] Fix Indefinite Length
  - [x] Enforce constructed construction
  - [x] Enforce same tag numbers for nested elements
- [x] Contracts / Invariants
  - [x] `BOOLEAN`, `INTEGER`, `ENUMERATED`, `OBJECT IDENTIFIER`, `BIT STRING`, `GeneralizedTime` and `UTCTime` are never less than 0 bytes
- [x] Add further `REAL` special numbers
- [x] Review latest version of X.690 (I was accidentally reading the 2002 one...)
- [x] Implement CER and DER restraints on `UTCTime` and `GeneralizedTime`
  - [x] Implement maximum lengths
    - [x] `UTCTime` min: 10, max: 17
    - [x] `GeneralizedTime` cannot exceed three characters after the decimal point. (min: 10, max: 23)
  - [x] Throw exception if comma is encountered
- [x] Implement new Exception hierarchy
  - [x] Get rid of `ASN1ValueInvalidException`
  - [x] Get rid of `message` variable in exception constructors
  - [x] `ASN1Exception`
    - [x] `ASN1CodecException`
      - [x] `ASN1RecursionException`
      - [x] `ASN1TruncationException`
      - [x] `ASN1TagException`
        - [x] `ASN1TagOverflowException`
        - [x] `ASN1TagPaddingException`
        - [x] `ASN1TagNumberException`
      - [x] `ASN1LengthException`
        - [x] `ASN1LengthOverflowException`
        - [x] `ASN1LengthUndefinedException`
      - [x] `ASN1ValueException`
        - [x] `ASN1ValueSizeException`
        - [x] `ASN1ValueOverflowException`
        - [x] `ASN1ValuePaddingException`
        - [x] `ASN1ValueCharactersException`
        - [x] `ASN1UndefinedException`
    - [x] `ASN1CompilerException`
- [x] More unit testing of `REAL`
- [x] Enforce correct construction
  - [x] Support constructed time types
  - [x] Make BER and CER enforce `this.value[0] == 0x00u` for each substring of a constructed `BIT STRING`
  - [x] Canonical Encoding Rules
    - [x] If encoding is constructed, accept only indefinite-length encoding
    - [x] If encoding is primitive, accept only definite-length encoding
  - [x] All rules (BER, CER, and DER)
    - [x] If using indefinite-length, accept only constructed form
- [x] Make properties for `END OF CONTENT` and `NULL` that just throw exceptions if its wrong
- [ ] Cross-Platform Testing
  - [ ] Windows 64-Bit
  - [x] Mac OS X 64-Bit
  - [x] Linux
    - [x] 64-Bit
    - [ ] 32-Bit
- [x] Comparison Testing with [PyASN1](http://pyasn1.sourceforge.net)
- [x] Field Testing
  - [x] Reading [X.509 Certificates](http://www.itu.int/rec/T-REC-X.509-201610-I/en)
  - [x] Creating a Session with [OpenLDAP Server](http://www.openldap.org)
  - [x] Test [OpenSSL](https://www.openssl.org/)'s [d2i tests](https://github.com/openssl/openssl/tree/master/test/d2i-tests)
- [x] Review ASN.1-related Common Vulnerabilities and Exploits (CVEs) in the [National Vulnerability Database](https://nvd.nist.gov)
- [x] Change copyright year to 2018
- [x] Grammar and Styling
  - [x] Check for `a` and `an` mixups
  - [x] Check for duplicated terminal words
  - [x] Check for incorrect data types
  - [x] Check for correct terminal spacing
  - [x] Add parenthetical abbreviations
  - [x] Remove trailing spaces
  - [x] Rename `ASN1ContextSwitchingTypeSyntaxes` to `ASN1Syntaxes`
  - [x] Format numbers consistently (particularly `0b` binary literals)
- [x] Documentation
  - [x] Redo embedded documentation
  - [x] `install.md`
  - [x] `compliance.md`
    - [x] Create a checklist for every bullet point of X.690.
    - [x] ~~Review that character-encoded `REAL`s are strictly conformant to [ISO 6093](https://www.iso.org/standard/12285.html)~~
    - [x] Comparison Tests
  - [x] `asn1.md`
    - [x] What the different classes are for
    - [x] What it means to be primitive or constructed
    - [x] "Don't use ASN.1 unless you absolutely MUST use ASN.1."
  - [x] `design.md`
  - [x] `library.md`
    - [x] Terminology
      - [x] This library uses "mantissa," not "significand," because "mantissa" is in the specification.
    - [x] Class Hierarchy
    - [x] Exception Hierarchy
    - [x] This library assumes IEEE 754 floating point structure
    - [x] Security Advice
      - [x] Leave note to developers about avoiding recursion problems. (See CVE-2016-4421 and CVE-2010-2284.)
      - [x] About constructed types (See CVE-2010-3445.)
    - [x] How to encode and decode
      - [x] `END OF CONTENT`
      - [x] `NULL`
      - [x] `ANY`
      - [x] `CHOICE`
      - [x] `INSTANCE OF`
      - [x] `SET OF`
      - [x] `SEQUENCE OF`
  - [x] `concurrency.md`
    - [x] Potential TOCTOU problems resulting
    - [x] Future inclusion of `synchronized` sections
    - [x] A better concurrency model
  - [x] `contributing.md`
  - [x] `security.md`
    - [x] OpenSSL Bads
    - [x] Fuzz Testing Results
    - [x] [National Vulnerability Database](https://nvd.nist.gov) Common Vulnerability and Exploit (CVE) Review
  - [x] `tools.md`
  - [x] `roadmap.md`
  - [x] `man` Pages
- [x] Build Scripts
  - [x] Add `chmod +x` to the build scripts for all executables
  - [x] Fix `echo` output problem on Mac
  - [x] Create dynamically-linked libraries as well
  - [x] Better `echo` messages
  - [x] [GNU Make](https://www.gnu.org/software/make/) `Makefile`
    - [x] Add a Make `install` target
    - [x] Add a Make `purge` target
  - [x] ~~Verbose linking~~ (I could not figure out how to do this.)
  - [x] Change `.lib` to `.a`.
  - [x] Put version in file names
  - [x] ~~Generate `.map` file~~ (It's not generating for some reason. Skipping.)
- [ ] `releases.csv` (Version, Date, LOC, SLOC, Signature)

#### Note 1:

From X.690, Section 8.19.2 on encoding of OIDs:

> The subidentifier shall be encoded in the fewest possible octets, that is, the leading octet of the subidentifier shall not have the value 0x80.

#### Note 2:

Due to [this bug that I found](https://issues.dlang.org/show_bug.cgi?id=18087),
I would either have to have no documentation for all mixin'd properties, since
embedded documentation does not appear to get generated after mixins are
applied, or I would have to split the getter-setter pairs for each property
into two separate mixins, which will make the use of the properties only work
if called syntactically like their method equivalents (e.g. `.prop(arg)`
instead of `.prop = arg`)

I tried doing this for the following properties:

* `integer`
* `objectIdentifier`
* `enumerated`
* `relativeObjectIdentifier`

### 1.0.1 Release

- [ ] Publish a [Dub package](https://code.dlang.org) for it
- [ ] Publish an [RPM package](https://access.redhat.com/sites/default/files/attachments/rpm_building_howto.pdf)
- [ ] Publish an [APT package](https://debian-handbook.info/browse/stable/debian-packaging.html)
- [ ] Publish a [Brew package](https://docs.brew.sh)
- [ ] Configure [Travis CI](https://travis-ci.org)
- [ ] Create `man(3)` (Library calls) pages
- [ ] Create Wikipedia pages for each codec
- [ ] Review by one security firm
- [ ] Add signatures with [my GPG key](http://jonathan.wilbur.space/downloads/jonathan@wilbur.space.gpg.pub)
- [ ] Marketing
  - [ ] "The ASN.1 Tour"
    - [ ] Tampa Hackerspace
    - [ ] Iron Yard
    - [ ] Gainesville Hackerspace
  - [ ] Share it on the [Dlang Subreddit](https://www.reddit.com/r/dlang/)
  - [ ] Share it on the [Dlang Blog](https://forum.dlang.org/group/announce)
  - [ ] Suggestions for Inclusions in D Libraries
    - [ ] [Botan](https://github.com/etcimon/botan)
    - [ ] [ldap](https://github.com/WebFreak001/ldap)
- [ ] Code Formatting
  - [ ] Format `switch` statements
  - [ ] Replace numbers with `enum`s in `ASN1TagNumberException` instantiations
- [ ] Unit tests based on examples from X.690
- [ ] Unit tests based on examples from the Dubuisson book
- [ ] Comparison tests to Go's ASN.1 library module
- [ ] Generate a `.def` file for Windows?
- [ ] Make tools build with the dynamically-linked library, if possible
- [ ] Build testing
  - [ ] OpenSolaris
  - [ ] FreeBSD

## Suggestions

I would like to have `debug` statements all throughout the code, but any method
in which I put a `write`, `writeln`, or `writefln` statement cannot be `nothrow`.
I would like a solution for this that:

1. Allows me to put a `debug` statement in _every_ method.
2. Allows methods to still be `nothrow`.
3. Does not use `version` statements that dramatically increase the lines of code.

If you have any great ideas, let me know.

## Bugs

The codecs are intended to be `final` classes, but due to
[this bug](https://issues.dlang.org/show_bug.cgi?id=17909) I found, it cannot
be until that bug is resolved.

## Special Thanks

* [Ilya Tingof](https://stackoverflow.com/users/1175029/ilya-etingof) ([@etingof](https://github.com/etingof)), who answered several questions of mine on StackOverflow, and who authored [PyASN1](http://pyasn1.sourceforge.net/).
* [@YuryStrozhevsky](https://github.com/YuryStrozhevsky) for his [ASN.1 BER Codec](https://github.com/YuryStrozhevsky/C-plus-plus-ASN.1-2008-coder-decoder) and his [@YuryStrozhevsky](https://github.com/YuryStrozhevsky)'s [ASN.1 Test Suite](https://github.com/YuryStrozhevsky/ASN1-2008-free-test-suite)

## See Also

* [X.680 - Abstract Syntax Notation One (ASN.1)](https://www.itu.int/rec/T-REC-X.680/en), published by the
[International Telecommunications Union](http://www.itu.int/en/pages/default.aspx).
* [X.690 - ASN.1 encoding rules](http://www.itu.int/rec/T-REC-X.690/en), published by the
[International Telecommunications Union](http://www.itu.int/en/pages/default.aspx).
* [ASN.1: Communication Between Heterogeneous Systems](http://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF) by Olivier Dubuisson

## Contact Me

If you would like to suggest fixes or improvements on this library, please just
[leave an issue on this GitHub page](https://github.com/JonathanWilbur/asn1-d/issues). If you would like to contact me for other reasons,
please email me at [jonathan@wilbur.space](mailto:jonathan@wilbur.space)
([My GPG Key](http://jonathan.wilbur.space/downloads/jonathan@wilbur.space.gpg.pub))
([My TLS Certificate](http://jonathan.wilbur.space/downloads/jonathan@wilbur.space.chain.pem)). :boar: