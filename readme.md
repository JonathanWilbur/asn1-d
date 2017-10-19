# ASN.1 D Library

* Author: [Jonathan M. Wilbur](http://jonathan.wilbur.space) <[jonathan@wilbur.space](mailto:jonathan@wilbur.space)>
* Copyright Year: 2017
* License: [ISC License](https://opensource.org/licenses/ISC)
* Version: [0.4.1](http://semver.org/)

**This library is not complete. It is uploaded here so the public can track my
progress on it and so that, if I get hit by a bus, my code survives.**

## What is ASN.1?

ASN.1 stands for *Abstract Syntax Notation*. ASN.1 messages can be encoded in
one of several encoding/decoding standards. It provides a system of types that
are extensible, and can presumably describe every protocol. You can think of it
as a protocol for describing other protocols as well as a family of standards
for encoding and decoding said protocols. It is similar to Google's Protocol Buffers.

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

### Current

Right now, I am only working on the Basic Encoding Rules module, since it will
pretty much be copy-and-paste, then deleting functionality, to create the other
modules, once I am done with BER. I want to make this module perfect before I
create the others. Here are the changes I have to make before I consider it
ready to serve as the basis for others:

- [x] Finish embedded documentation
  - [x] `Throws`
  - [x] `Returns`
  - [x] `See_Also`
  - [x] `Standards`
  - [x] DDoc Section Formatting Macros
- [x] Unabbreviated member names and abbreviated aliases
- [x] Storage classes (`in`, `out`, `scope`, `const`, etc.)
- [x] `@safe`, `@trusted`, `@system`, etc.
- [x] `nothrow`, `pure`, `final`, etc.
- [ ] Character-encoded `REAL`
- [x] `integer(T) if (isSigned!T && isIntegral!T)`
- [ ] Figure out the situation with `BitArray` (I am seriously considering just returning `bool[]` instead.)
- [ ] Abstractions for `set` and `sequence` properties \([StackOverflow Question](https://stackoverflow.com/questions/46828692/template-referring-to-child-class-within-parent-class)\)
- [x] A better system of exceptions
- [ ] 100% unit test code coverage
  - [ ] Negative unit tests for all string types
- [ ] Add `deprecated` attribute to deprecated types.
- [ ] Make constructor that takes ref to a `size_t` storing the number of bytes read
- [ ] Overhaul OID and RelativeOID
  - [ ] Fix `opCmp`
- [ ] Rename `BERValue` to `BERElement` and `ASN1Value` to `ASN1Element`

### Future

The following codecs will be a part of the library:

- [ ] Distinguished Encoding Rules (DER)
- [ ] Basic Encoding Rules (BER)
- [ ] Canonical Encoding Rules (CER)
- [ ] XML Encoding Rules (XER)
- [ ] Canonical XML Encoding Rules (CXER)
- [ ] Extended XML Encoding Rules (EXER)
- [ ] Aligned Packed Encoding Rules (PER)
- [ ] Unaligned Packed Encoding Rules (UPER)
- [ ] Canonical Packed Encoding Rules (CPER)
- [ ] Octet Encoding Rules (OER)
- [ ] Canonical Octet Encoding Rules (COER)
- [ ] JSON Encoding Rules (JER)
- [ ] Generic String Encoding Rules (GSER)
- [ ] Lightweight Encoding Rules (LWER)
- [ ] BACNet Encoding Rules
- [ ] Signalling-specific Encoding Rules (SER)

The Code will have the following features:

- [ ] Storage classes applied to all parameters

The following testing will be done:

- [ ] At least one unit test for every method or function, including tests covering all code pathways in every method or function
- [ ] Fuzz testing (Sending random bytes to a decoder to get something unexpected)
- [ ] Cross-Platform Testing
  - [ ] Windows
  - [ ] Mac OS X
  - [ ] Linux
- [ ] Comparison Testing (Comparing the behavior of this library with others)
  - [ ] PyASN1
- [ ] Field Testing
  - [ ] Reading X.509 Certificates
  - [ ] Creating a Session with OpenLDAP Server
  - [ ] Creating a Session with a TLS Endpoint

The following documentation will be done:

- [ ] Embedded Documentation for everything
- [ ] Formal citations for unit tests

The following reviews will be done:

- [ ] Review by one security firm
- [ ] Review for HeartBleed-like vulnerabilities
- [ ] Review of all ASN.1-related CVEs

The following build mechanisms will be implemented:

- [ ] Bazel
- [ ] D File / Compiled Executable
- [ ] Bash Script
- [x] Batch Script
- [ ] GNU Make File

The library will be marketed and distributed in the following ways:

- [ ] Create a website for it
- [ ] Publish a Dub package for it
- [ ] Share it on the Dlang Subreddit
- [ ] Publish an RPM package 
- [ ] Publish an APT package

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