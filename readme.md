# ASN.1 D Library

* Author: [Jonathan M. Wilbur](http://jonathan.wilbur.space) <[jonathan@wilbur.space](mailto:jonathan@wilbur.space)>
* Copyright Year: 2017
* License: [ISC License](https://opensource.org/licenses/ISC)
* Version: [0.8.2](http://semver.org/)

**This library is not complete. It is uploaded here so the public can track my
progress on it and so that, if I get hit by a bus, my code survives.**

## What is ASN.1?

ASN.1 stands for *Abstract Syntax Notation*. ASN.1 was first specified in 
[X.680 - Abstract Syntax Notation One (ASN.1)](https://www.itu.int/rec/T-REC-X.680/en),
by the [International Telecommunications Union](http://www.itu.int/en/pages/default.aspx).
ASN.1 messages can be encoded in one of several encoding/decoding standards. 
It provides a system of types that are extensible, and can presumably describe 
every protocol. You can think of it as a protocol for describing other protocols 
as well as a family of standards for encoding and decoding said protocols. 
It is similar to [Google's Protocol Buffers](https://developers.google.com/protocol-buffers/).

## Why ASN.1?

ASN.1 is used in multiple technologies, including:

* SSL/TLS messages are encoded in ASN.1's Distinguished Encoding Rules
* LDAP and X.500 messages are encoded in ASN.1's Basic Encoding Rules
* The magnetic stripes on the back of your credit card use some ASN.1 variant.
* Microsoft's Remote Desktop Protocol uses ASN.1's Packed Encoding Rules.
* Simple Network Management Protocol (SNMP) uses ASN.1's Basic Encoding Rules
* CMIP?
* Signalling System Number 7 (SS7), used to make most phone calls on the Public Switched Telephone Network (PSTN).
* H.323 Video conferencing
* BIP, CBEFF, and ACBio Biometrics
* PBX control (CSTA)
* Intelligent transportation (SAE J2735)
* Cellular telephony (GSM, GPRS/EDGE, UMTS, LTE)

Source for some of these: [PyASN1](http://pyasn1.sourceforge.net/)

So, before we even begin to develop new TLS, LDAP, or RDP libraries in the
D programming language, it is important that we get a grasp of ASN.1 first.

## Structure

If you want to learn about how to use this library, your best source at the
moment is to start with `source/codecs/ber/ber.d`. The API exposed by that
file is what a developer who needed an ASN.1 BER codec would use.

I am not going to document the usage of this library just yet, because it
is just too volatile at this point.

## Development

I hope to be done with this library before the end of 2017. When it is
complete, it will contain several codecs, and everything will be unit-tested 
and reviewed for security and performance.

### Pre-1.0.0-alpha Development

- [x] Finish embedded documentation
  - [x] `Throws`
  - [x] `Returns`
  - [x] `See_Also`
  - [x] `Standards`
  - [x] DDoc Section Formatting Macros
  - [ ] Test that it actually compiles correctly
- [x] Unabbreviated member names and abbreviated aliases
- [x] Storage classes (`in`, `out`, `scope`, `const`, etc.)
- [x] `@safe`, `@trusted`, `@system`, etc.
- [x] `nothrow`, `pure`, `final`, etc.
- [x] Character-encoded `REAL`
- [x] `integer(T) if (isSigned!T && isIntegral!T)`
- [x] Convert `bitString` to get and set a `bool[]` instead of `std.bitmanip.BitArray`
- [x] Abstractions for `set` and `sequence` properties \([StackOverflow Question](https://stackoverflow.com/questions/46828692/template-referring-to-child-class-within-parent-class)\)
- [x] A better system of exceptions
- [x] 100% unit test code coverage
- [x] Add `deprecated` attribute to deprecated types.
- [x] Contracts
- [x] Make all accessors `const` or `immutable`
- [x] Overhaul OID and RelativeOID
- [x] Make constructor that takes ref to a `size_t` storing the number of bytes read
- [x] Test long definite encoding
- [x] Test indefinite encoding
- [x] Unit tests for OID Types
  - [x] `ObjectIdentifierNode`
  - [x] `ObjectIdentifier`
- [x] Remove dependency on `std.outbuffer`
- [x] Experiment with putting unit tests in abstract class
- [x] Abstract constructed types into parent class, `ASN1BinaryValue`
  - [x] `External`
  - [x] `EmbeddedPDV`
  - [x] `CharacterString`
- [ ] Better exception messages
  - [x] URIs to documentation
  - [ ] Unique numbers
  - [ ] Display Values
- [x] Rename `BERValue` to `BERElement` and `ASN1Value` to `ASN1Element`
- [x] Rename `ASN1InvalidValueException` to `ASN1ValueInvalidException`
- [ ] `debug` statements
- [ ] Get rid of deprecation messages (Might be caused by [this bug](https://issues.dlang.org/show_bug.cgi?id=15903))
- [ ] Formal citations for unit tests
- [ ] Modify `realType()` binary decoding to use pointer casting instead of or-shift loops.
- [ ] Build System
  - [ ] [Bazel](https://www.bazel.build)
  - [ ] D File / Compiled Executable
  - [ ] Bash Script
  - [x] Batch Script
  - [ ] GNU Make File

Version 1.0.0-alpha development is expected to begin on November 1st, 2017.

### 1.0.0-alpha Development

Version 1.0.0-alpha development will consist entirely of creating these codecs:

- [ ] Distinguished Encoding Rules (DER)
- [ ] Basic Encoding Rules (BER)
- [ ] Canonical Encoding Rules (CER)

Version 1.0.0-alpha is expected to be released around November 12th, 2017.

### 1.0.0-beta Development

Version 1.0.0-beta is expected to be released around November 30th, 2017.

- [ ] Fuzz testing (Sending random bytes to a decoder to get something unexpected)
- [ ] Cross-Platform Testing
  - [ ] Windows
  - [ ] Mac OS X
  - [ ] Linux
- [ ] Comparison Testing with
  - [ ] [PyASN1](http://pyasn1.sourceforge.net)
  - [ ] @YuryStrozhevsky 's [ASN1 BER Codec](https://github.com/YuryStrozhevsky/C-plus-plus-ASN.1-2008-coder-decoder)
- [ ] Field Testing
  - [ ] Reading X.509 Certificates
  - [ ] Creating a Session with [OpenLDAP Server](http://www.openldap.org)
  - [ ] Creating a Session with a TLS Endpoint
  - [ ] @YuryStrozhevsky 's [ASN1 Test Suite](https://github.com/YuryStrozhevsky/ASN1-2008-free-test-suite)
- [ ] Build Version Testing
  - [ ] `-noboundscheck`
- [ ] Review by one security firm
- [ ] Review for HeartBleed-like vulnerabilities
- [ ] Review of all ASN.1-related CVEs
- [ ] Review that character-encoded `REAL`s are strictly conformant to ISO 6093 (Maybe even make an ISO 6093 Library...)

### 1.0.0 Release

- [ ] Publish a [Dub package](https://code.dlang.org) for it
- [ ] Share it on [the Dlang Subreddit](https://www.reddit.com/r/dlang/)
- [ ] [Publish an RPM package](https://access.redhat.com/sites/default/files/attachments/rpm_building_howto.pdf)
- [ ] [Publish an APT package](https://debian-handbook.info/browse/stable/debian-packaging.html)
- [ ] Configure [Travis CI](https://travis-ci.org)
- [ ] Dynamically-linked libraries
- [ ] Create `man(1)` (executables) and `man(3)` (Library calls) pages

### 1.1.0 Release

The following codecs will be added:

- [ ] Aligned Packed Encoding Rules (PER)
- [ ] Unaligned Packed Encoding Rules (UPER)
- [ ] Canonical Packed Encoding Rules (CPER)

### 1.2.0 Release

The following codecs will be added:

- [ ] JSON Encoding Rules (JER)
- [ ] XML Encoding Rules (XER)
- [ ] Canonical XML Encoding Rules (CXER)
- [ ] Extended XML Encoding Rules (EXER)

### 1.3.0 Release

The following codecs will be added:

- [ ] Octet Encoding Rules (OER)
- [ ] Canonical Octet Encoding Rules (COER)

### 1.4.0 Release

The following codecs will be added:

- [ ] Generic String Encoding Rules (GSER)
- [ ] Lightweight Encoding Rules (LWER)
- [ ] BACNet Encoding Rules
- [ ] Signalling-specific Encoding Rules (SER)

### 1.5.0 Release

The following command line tools will be released:

- [ ] `encode-der`
- [ ] `encode-ber`
- [ ] `encode-cer`
- [ ] `encode-xer`
- [ ] `encode-cxer`
- [ ] `encode-exer`
- [ ] `encode-per`
- [ ] `encode-uper`
- [ ] `encode-cper`
- [ ] `encode-oer`
- [ ] `encode-coer`
- [ ] `encode-jer`
- [ ] `encode-gser`
- [ ] `encode-lwer`
- [ ] `encode-bacnet`
- [ ] `encode-ser`
- [ ] `decode-der`
- [ ] `decode-ber`
- [ ] `decode-cer`
- [ ] `decode-xer`
- [ ] `decode-cxer`
- [ ] `decode-exer`
- [ ] `decode-per`
- [ ] `decode-uper`
- [ ] `decode-cper`
- [ ] `decode-oer`
- [ ] `decode-coer`
- [ ] `decode-jer`
- [ ] `decode-gser`
- [ ] `decode-lwer`
- [ ] `decode-bacnet`
- [ ] `decode-ser`

## Bugs

The codecs are intended to be `final` classes, but due to 
[this bug](https://issues.dlang.org/show_bug.cgi?id=17909) I found, it cannot
be until that bug is resolved.

## See Also

* [X.680 - Abstract Syntax Notation One (ASN.1)](https://www.itu.int/rec/T-REC-X.680/en), published by the
[International Telecommunications Union](http://www.itu.int/en/pages/default.aspx).
* [X.690 - ASN.1 encoding rules](http://www.itu.int/rec/T-REC-X.690/en), published by the
[International Telecommunications Union](http://www.itu.int/en/pages/default.aspx).

## Contact Me

If you would like to suggest fixes or improvements on this library, please just
comment on this on GitHub. If you would like to contact me for other reasons,
please email me at [jonathan@wilbur.space](mailto:jonathan@wilbur.space). :boar: