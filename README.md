# ASN.1 D Library

* Author: [Jonathan M. Wilbur](http://jonathan.wilbur.space) <[jonathan@wilbur.space](mailto:jonathan@wilbur.space)>
* Copyright Year: 2017
* License: [MIT License](https://mit-license.org/)
* Version: [1.0.0-beta.31](http://semver.org/)

**Expected Version 1.0.0 Release Date: December 31st, 2017**

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

Source for some of these: [PyASN1](http://pyasn1.sourceforge.net/)

If you look in the `asn1` directory of WireShark's source code, you'll see all
of the protocols that use ASN.1.

## Structure

The "root" of this library is `asn1.d`, which contains some universal absolutes,
such as `enum`s and `const`s that are used by ASN.1. But this is a pretty boring
file with almost no actual code.

The real fun begins with `source/codec.d`, whose flagship item is `ASN1Element`, 
the abstract class from which all other codecs must inherit. An `ASN1Element` 
represents a single encoded value (although it could be a single `SEQUENCE`
or `SET`). In the `source/codecs` directory, you will find all of the codecs that
inherit from `ASN1Element`. The `BERElement` class can be found in `ber.d`,
and it represents a ASN.1 value, encoded via the Basic Encoding Rules (BER)
specified in the 
[International Telecommunications Union](http://www.itu.int/en/pages/default.aspx)'s
[X.690 - ASN.1 encoding rules](http://www.itu.int/rec/T-REC-X.690/en).

The codecs rely upon a few ASN.1-specific data types, such as `EMBEDDED PDV`,
and these data types have their own classes or structs somewhere in the
`source/types` directory. In `source/types`, you will find `alltypes.d`, which
just provides a convenient way to import all data types instead of having
multiple import statements for each. There, you will also find data types
that are used by other data types. In `source/types/universal`, you will find
D data types for some of ASN.1's universal data types.

In the `source/tools` directory, you will find the source for this
library's related ASN.1 command-line tools, such as `decode-ber`.

In the `documentation` directory, you will find documentation. The 
automatically-generated DDoc HTML (produced from the commentary documentation)
can be found in `documentation/html`. URIs to useful websites can be found
in `documentation/links`. The list of developers for this library can be found
in CSV-format in `documentation/credits.csv`, where the fields are `role`, 
`full name`, and `email address` for each row. In `documentation/license`,
you will find the full text of the license for this library.

In the `build` directory, you will find tools for building the library, and
directories for the placement of outputs or intermediary artifacts (midputs?).
The most important subdirectory for you, the end user, is going to be 
`build/scripts`, which contains various scripts for building this library in
a variety of environments.

## Compile and Install

In `build/scripts` there are three scripts you can use to build the library.
When the library is built, it will be located in `build/libraries`.

### On POSIX-Compliant Machines (Linux, Mac OS X)

Run `./build/scripts/build.sh`.
If you get a permissions error, you need to set that file to be executable
using the `chmod` command.

### On Windows

Run `.\build\scripts\build.bat` from a `cmd` or run `.\build\scripts\build.ps1`
from the PowerShell command line. If you get a warning about needing a 
cryptographic signature for the PowerShell script, it is probably because
your system is blocking running unsigned PowerShell scripts. Just run the
other script if that is the case.

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
- [ ] Check for:
  - [ ] `TODO`
  - [ ] `FIXME`
  - [ ] `REVIEW`
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
- [x] Redo Context-Switching Types
  - [x] Make them actually work
  - [x] Support the pre-1994 `EXTERNAL`
  - [x] Deprecate `EXTERNAL`
  - [x] Document all of the fields
  - [x] Unittest all variations of `EXTERNAL`'s `encoding`
  - [x] ~~Implement `OBJECT IDENTIFIER` restrictions for `CharacterString`~~ (I can't find documentation of this.)
- [x] Add Object Identifier constants from Section 12 of X.690
- [ ] Make as much code `const` or `immutable` as possible
  - [ ] This still needs to be done for constructors.
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
- [ ] Command Line Tools
  - [x] Create a template mixin or something to reduce duplication between decoders.
  - [x] `encode-der`
  - [x] `encode-ber`
  - [x] `encode-cer`
  - [x] `decode-der`
  - [x] `decode-ber`
  - [x] `decode-cer`
  - [ ] Fix them
  - [ ] Catch exceptions and display error message.
- [x] Test that all one-byte elements throw exceptions
- [x] Test an OID with a node with a values 127, 128, and 0.
- [x] Test even more significant mathematical values with `realType()`:
  - [x] `sqrt(2)/2`
  - [x] The golden ratio
  - [x] Everything [here](https://en.wikipedia.org/wiki/Mathematical_constant)
  - [x] `max` of every integral type
  - [x] `min` of every integral type
- [x] Test that .length > 1000 octetStrings cannot modify their references
- [x] Test really large items
- [x] Encode `INTEGER` of 0 as a single null byte and, decode it as such.
- [x] Fuzz testing to ensure `RangeError` is never thrown. If it is thrown, it means that there are vulnerabilities if compiled with `-boundscheck=off` flag.
  - [x] Fuzz test all possible two-byte combinations
  - [x] Fuzz test all possible three-byte combinations
- [x] Enforce `0` padding bits for DER and CER-encoded `BIT STRING`
- [x] Test a `BIT STRING` with only a first byte
- [ ] Do some more unit testing for extreme lengths.
- [x] Fix Indefinite Length
- [x] Contracts / Invariants
  - [x] `BOOLEAN`, `INTEGER`, `ENUMERATED`, `OBJECT IDENTIFIER`, `BIT STRING`, `GeneralizedTime` and `UTCTime` are never less than 0 bytes
- [ ] Cross-Platform Testing
  - [ ] Windows (Which is Big-Endian)
    - [ ] 64-Bit
    - [ ] 32-Bit
  - [x] Mac OS X (Which is Little-Endian)
    - [x] 64-Bit
  - [x] Linux (Which is Little-Endian)
    - [x] 64-Bit
    - [ ] 32-Bit
- [x] Comparison Testing with [PyASN1](http://pyasn1.sourceforge.net)
- [x] Field Testing
  - [x] Reading [X.509 Certificates](http://www.itu.int/rec/T-REC-X.509-201610-I/en)
  - [x] Creating a Session with [OpenLDAP Server](http://www.openldap.org)
  - [x] Test [OpenSSL](https://www.openssl.org/)'s [d2i tests]()
- [x] Review ASN.1-related Common Vulnerabilities and Exploits (CVEs) Review 
      in [National Vulnerability Database](https://nvd.nist.gov)
  - [x] ~~[CVE-2017-11496](https://nvd.nist.gov/vuln/detail/CVE-2017-11496)~~
  - [x] [CVE-2017-9023](https://nvd.nist.gov/vuln/detail/CVE-2017-9023)
  - [x] [CVE-2016-7053](https://nvd.nist.gov/vuln/detail/CVE-2016-7053)
  - [x] [CVE-2016-6129](https://nvd.nist.gov/vuln/detail/CVE-2016-6129)
  - [x] [CVE-2016-9939](https://nvd.nist.gov/vuln/detail/CVE-2016-9939)
  - [x] ~~[CVE-2016-6891](https://nvd.nist.gov/vuln/detail/CVE-2016-6891)~~
  - [x] ~~[CVE-2016-5080](https://nvd.nist.gov/vuln/detail/CVE-2016-5080)~~
  - [x] [CVE-2016-0758](https://nvd.nist.gov/vuln/detail/CVE-2016-0758)
  - [x] [CVE-2015-5726](https://nvd.nist.gov/vuln/detail/CVE-2015-5726)
  - [x] [CVE-2016-2176](https://nvd.nist.gov/vuln/detail/CVE-2016-2176)
  - [x] [CVE-2016-2109](https://nvd.nist.gov/vuln/detail/CVE-2016-2109)
  - [x] [CVE-2016-2108](https://nvd.nist.gov/vuln/detail/CVE-2016-2108)
  - [x] [CVE-2016-2053](https://nvd.nist.gov/vuln/detail/CVE-2016-2053)
  - [x] [CVE-2016-4421](https://nvd.nist.gov/vuln/detail/CVE-2016-4421)
  - ~~[x] [CVE-2016-4418](https://nvd.nist.gov/vuln/detail/CVE-2016-4418)~~
  - [x] ~~[CVE-2016-2427](https://nvd.nist.gov/vuln/detail/CVE-2016-2427)~~
  - [x] [CVE-2016-1950](https://nvd.nist.gov/vuln/detail/CVE-2016-1950)
  - [x] [CVE-2016-2842](https://nvd.nist.gov/vuln/detail/CVE-2016-2842)
  - [x] [CVE-2016-0799](https://nvd.nist.gov/vuln/detail/CVE-2016-0799)
  - [x] [CVE-2016-2522](https://nvd.nist.gov/vuln/detail/CVE-2016-2522)
  - [x] [CVE-2015-7540](https://nvd.nist.gov/vuln/detail/CVE-2015-7540)
  - [x] ~~[CVE-2015-7061](https://nvd.nist.gov/vuln/detail/CVE-2015-7061)~~
  - [x] ~~[CVE-2015-7060](https://nvd.nist.gov/vuln/detail/CVE-2015-7060)~~
  - [x] ~~[CVE-2015-7059](https://nvd.nist.gov/vuln/detail/CVE-2015-7059)~~
  - [x] [CVE-2015-3194](https://nvd.nist.gov/vuln/detail/CVE-2015-3194)
  - [x] ~~[CVE-2015-7182](https://nvd.nist.gov/vuln/detail/CVE-2015-7182)~~
  - [x] [CVE-2015-1790](https://nvd.nist.gov/vuln/detail/CVE-2015-1790)
  - [x] [CVE-2015-0289](https://nvd.nist.gov/vuln/detail/CVE-2015-0289)
  - [x] [CVE-2015-0287](https://nvd.nist.gov/vuln/detail/CVE-2015-0287)
  - [x] [CVE-2015-0208](https://nvd.nist.gov/vuln/detail/CVE-2015-0208)
  - [x] ~~[CVE-2015-1182](https://nvd.nist.gov/vuln/detail/CVE-2015-1182)~~
  - [x] [CVE-2014-1569](https://nvd.nist.gov/vuln/detail/CVE-2014-1569)
  - [x] ~~[CVE-2014-4443](https://nvd.nist.gov/vuln/detail/CVE-2014-4443)~~
  - [x] ~~[CVE-2014-1568](https://nvd.nist.gov/vuln/detail/CVE-2014-1568)~~
  - [x] [CVE-2014-5165](https://nvd.nist.gov/vuln/detail/CVE-2014-5165)
  - [x] [CVE-2014-3468](https://nvd.nist.gov/vuln/detail/CVE-2014-3468)
  - [x] ~~[CVE-2014-3467](https://nvd.nist.gov/vuln/detail/CVE-2014-3467)~~
  - [x] ~~[CVE-2014-1316](https://nvd.nist.gov/vuln/detail/CVE-2014-1316)~~
  - [x] [CVE-2013-5018](https://nvd.nist.gov/vuln/detail/CVE-2013-5018)
  - [x] [CVE-2013-4935](https://nvd.nist.gov/vuln/detail/CVE-2013-4935)
  - [x] ~~[CVE-2013-3557](https://nvd.nist.gov/vuln/detail/CVE-2013-3557)~~
  - [x] [CVE-2013-3556](https://nvd.nist.gov/vuln/detail/CVE-2013-3556)
  - [x] [CVE-2012-0441](https://nvd.nist.gov/vuln/detail/CVE-2012-0441)
  - [x] [CVE-2012-1569](https://nvd.nist.gov/vuln/detail/CVE-2012-1569)
  - [x] [CVE-2011-1142](https://nvd.nist.gov/vuln/detail/CVE-2011-1142)
  - [x] [CVE-2011-0445](https://nvd.nist.gov/vuln/detail/CVE-2011-0445)
  - [x] [CVE-2010-3445](https://nvd.nist.gov/vuln/detail/CVE-2010-3445)
  - [x] ~~[CVE-2010-2994](https://nvd.nist.gov/vuln/detail/CVE-2010-2994)~~
  - [x] ~~[CVE-2010-2284](https://nvd.nist.gov/vuln/detail/CVE-2010-2284)~~
  - [x] ~~[CVE-2009-3877](https://nvd.nist.gov/vuln/detail/CVE-2009-3877)~~
  - [x] ~~[CVE-2009-3876](https://nvd.nist.gov/vuln/detail/CVE-2009-3876)~~
  - [x] ~~[CVE-2009-2511](https://nvd.nist.gov/vuln/detail/CVE-2009-2511)~~
  - [x] ~~[CVE-2009-2661](https://nvd.nist.gov/vuln/detail/CVE-2009-2661)~~
  - [x] [CVE-2009-2185](https://nvd.nist.gov/vuln/detail/CVE-2009-2185)
  - [x] [CVE-2009-0847](https://nvd.nist.gov/vuln/detail/CVE-2009-0847)
  - [x] [CVE-2009-0846](https://nvd.nist.gov/vuln/detail/CVE-2009-0846)
  - [x] [CVE-2009-0789](https://nvd.nist.gov/vuln/detail/CVE-2009-0789)
  - [x] ~~[CVE-2008-2952](https://nvd.nist.gov/vuln/detail/CVE-2008-2952)~~
  - [x] ~~[CVE-2008-1673](https://nvd.nist.gov/vuln/detail/CVE-2008-1673)~~
  - [x] ~~[CVE-2006-3894](https://nvd.nist.gov/vuln/detail/CVE-2006-3894)~~
  - [x] ~~[CVE-2006-6836](https://nvd.nist.gov/vuln/detail/CVE-2006-6836)~~
  - [x] ~~[CVE-2006-2937](https://nvd.nist.gov/vuln/detail/CVE-2006-2937)~~
  - [x] ~~[CVE-2006-1939](https://nvd.nist.gov/vuln/detail/CVE-2006-1939)~~
  - [x] ~~[CVE-2006-0645](https://nvd.nist.gov/vuln/detail/CVE-2006-0645)~~
  - [x] [CVE-2005-1730](https://nvd.nist.gov/vuln/detail/CVE-2005-1730)
  - [x] ~~[CVE-2005-1935](https://nvd.nist.gov/vuln/detail/CVE-2005-1935)~~
  - [x] ~~[CVE-2004-2344](https://nvd.nist.gov/vuln/detail/CVE-2004-2344)~~
  - [x] [CVE-2004-2644](https://nvd.nist.gov/vuln/detail/CVE-2004-2644)
  - [x] [CVE-2004-2645](https://nvd.nist.gov/vuln/detail/CVE-2004-2645)
  - [x] [CVE-2004-0642](https://nvd.nist.gov/vuln/detail/CVE-2004-0642)
  - [x] [CVE-2004-0644](https://nvd.nist.gov/vuln/detail/CVE-2004-0644)
  - [x] ~~[CVE-2004-0699](https://nvd.nist.gov/vuln/detail/CVE-2004-0699)~~
  - [x] ~~[CVE-2004-0123](https://nvd.nist.gov/vuln/detail/CVE-2004-0123)~~
  - [x] ~~[CVE-2003-0818](https://nvd.nist.gov/vuln/detail/CVE-2003-0818)~~
  - [x] ~~[CVE-2005-1247](https://nvd.nist.gov/vuln/detail/CVE-2005-1247)~~
  - [x] ~~[CVE-2003-1005](https://nvd.nist.gov/vuln/detail/CVE-2003-1005)~~
  - [x] [CVE-2003-0564](https://nvd.nist.gov/vuln/detail/CVE-2003-0564)
  - [x] ~~[CVE-2003-0565](https://nvd.nist.gov/vuln/detail/CVE-2003-0565)~~
  - [x] [CVE-2003-0851](https://nvd.nist.gov/vuln/detail/CVE-2003-0851)
  - [x] [CVE-2003-0543](https://nvd.nist.gov/vuln/detail/CVE-2003-0543)
  - [x] [CVE-2003-0544](https://nvd.nist.gov/vuln/detail/CVE-2003-0544)
  - [x] [CVE-2003-0545](https://nvd.nist.gov/vuln/detail/CVE-2003-0545)
  - [x] [CVE-2003-0430](https://nvd.nist.gov/vuln/detail/CVE-2003-0430)
  - [x] ~~[CVE-2002-0036](https://nvd.nist.gov/vuln/detail/CVE-2002-0036)~~
  - [x] ~~[CVE-2002-0353](https://nvd.nist.gov/vuln/detail/CVE-2002-0353)~~
- [ ] Grammar and Styling
  - [ ] Check for `a` and `an` mixups
  - [ ] Check for duplicated terminal words
  - [ ] Check for incorrect data types
  - [ ] Check for correct terminal spacing
  - [ ] Add parenthetical abbreviations
  - [ ] Ensure all numeric literals end with `u`
  - [ ] Remove trailing spaces
  - [ ] Use either the term `byte` or `octet` consistently for variable names
    - [ ] Especially in `toBytes()`
  - [x] Rename `ASN1ContextSwitchingTypeSyntaxes` to `ASN1Syntaxes`
- [ ] `cli.lib`
  - [ ] Figure out how to parse negative numbers from the command-line (`-1.0` gets interpreted as a command...)
- [ ] Documentation
  - [ ] `build.md`
    - [ ] Instructions on installing and linking `cli.lib`.
  - [ ] `compliance.md`
    - [ ] Create a checklist for every bullet point of X.690.
    - [ ] Review that character-encoded `REAL`s are strictly conformant to [ISO 6093](https://www.iso.org/standard/12285.html) (Maybe even make an ISO 6093 Library...)
    - [x] Comparison Tests
  - [ ] `asn1.md`
    - [ ] What the different classes are for
    - [ ] What it means to be primitive or constructed
    - [ ] "Don't use ASN.1 unless you absolutely MUST use ASN.1."
  - [ ] `library.md`
    - [ ] Class Hierarchy
    - [ ] Exception Hierarchy
    - [ ] Security Advice
      - [ ] Leave note to developers about avoiding recursion problems. (See CVE-2016-4421 and CVE-2010-2284.)
      - [ ] About constructed types (See CVE-2010-3445.)
    - [ ] How to encode and decode
      - [ ] `ANY`
      - [ ] `CHOICE` (Mind CVE-2011-1142)
      - [ ] `INSTANCE OF`
      - [ ] `SET OF`
      - [ ] `SEQUENCE OF`
  - [ ] `contributing.md`
  - [ ] `context-switching-types.md` (My research into context-switching types)
  - [x] `security.md`
    - [x] OpenSSL Bads
    - [x] Fuzz Testing Results
    - [x] [National Vulnerability Database](https://nvd.nist.gov) Common Vulnerability and Exploit (CVE) Review
  - [ ] `tools.md`
  - [ ] `roadmap.md`
  - [ ] `releases.csv` (Version, Date, LOC, SLOC, Signature)
  - [ ] `users.md` / `users.csv`
  - [ ] `man` Pages
- [ ] Build Scripts
  - [ ] Add `chmod +x` to the build scripts for all executables
  - [ ] Create dynamically-linked libraries as well
  - [ ] [GNU Make](https://www.gnu.org/software/make/) `Makefile`
  - [ ] Generate a `.def` file for Windows?

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

### 1.0.0 Release

- [ ] Publish a [Dub package](https://code.dlang.org) for it
- [ ] Publish an [RPM package](https://access.redhat.com/sites/default/files/attachments/rpm_building_howto.pdf)
- [ ] Publish an [APT package](https://debian-handbook.info/browse/stable/debian-packaging.html)
- [ ] Publish a [Brew package](https://docs.brew.sh)
- [ ] Configure [Travis CI](https://travis-ci.org)
- [ ] Create `man(1)` (executables) and `man(3)` (Library calls) pages
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

### 1.1.0 Release

The following codecs will be added:

- [ ] [Aligned Packed Encoding Rules (PER)](http://www.itu.int/rec/T-REC-X.691-201508-I)
- [ ] Unaligned Packed Encoding Rules (UPER)
- [ ] [Canonical Packed Encoding Rules (CPER)](http://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-per`
  - [ ] `encode-uper`
  - [ ] `encode-cper`
  - [ ] `decode-per`
  - [ ] `decode-uper`
  - [ ] `decode-cper`

After this release, developers will be able to use this library to develop a
Remote Desktop Protocol library.

### 1.2.0 Release

The following codecs will be added:

- [ ] [JSON Encoding Rules (JER)](http://www.itu.int/rec/T-REC-X.697-201710-P)
- [ ] [XML Encoding Rules (XER)](http://www.itu.int/rec/T-REC-X.693-201508-I/en)
- [ ] [Canonical XML Encoding Rules (CXER)](http://www.itu.int/rec/T-REC-X.693-201508-I/en)
- [ ] [Extended XML Encoding Rules (EXER)](http://www.itu.int/rec/T-REC-X.693-201508-I/en)
- [ ] Command-Line Tools
  - [ ] `encode-xer`
  - [ ] `encode-cxer`
  - [ ] `encode-exer`
  - [ ] `encode-jer`
  - [ ] `decode-xer`
  - [ ] `decode-cxer`
  - [ ] `decode-exer`
  - [ ] `decode-jer`

### 1.3.0 Release

The following codecs will be added:

- [ ] [Octet Encoding Rules (OER)](http://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] [Canonical Octet Encoding Rules (COER)](http://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-oer`
  - [ ] `encode-coer`
  - [ ] `decode-oer`
  - [ ] `decode-coer`

### 1.4.0 Release

The following codecs will be added:

- [ ] Generic String Encoding Rules (GSER)
- [ ] Lightweight Encoding Rules (LWER)
- [ ] BACNet Encoding Rules
- [ ] Signalling-specific Encoding Rules (SER)
- [ ] Command-Line Tools
  - [ ] `encode-gser`
  - [ ] `encode-lwer`
  - [ ] `encode-bacnet`
  - [ ] `encode-ser`
  - [ ] `decode-gser`
  - [ ] `decode-lwer`
  - [ ] `decode-bacnet`
  - [ ] `decode-ser`

### 1.6.0 Release

- [ ] Scale selection for binary-encoded `REAL` type

### 2.0.0 Release

- [ ] Teletex (T61String) validation (WireShark has an implementation.)
- [ ] Videotex validation
- [ ] Included Source Signature
- [ ] Better Indefinite Length support
  - [ ] Recursively parse the subelements.
  - [ ] Enforce constructed construction.
- [ ] Operator Overloads
  - [ ] `~=` making a constructed element
- [ ] Build System
  - [ ] [Bazel](https://www.bazel.build)
  - [ ] Makefile
  - [ ] Compiled D Executable
  - [ ] Support `gdc` and `ldc` compilation
- [ ] Libraries (Intended to split off into independent modules once I figure out good packaging, distribution, and build processes for them)
  - [x] `cli` ([GitHub Page](https://github.com/JonathanWilbur/cli-d))
  - [ ] `teletex`
  - [ ] `videotex`
  - [ ] `bin2text`
    - [ ] `Base2`
    - [ ] `Base8`
    - [ ] `Base10`?
    - [ ] `Base16`
    - [ ] `Base64`

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