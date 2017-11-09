# ASN.1 D Library

* Author: [Jonathan M. Wilbur](http://jonathan.wilbur.space) <[jonathan@wilbur.space](mailto:jonathan@wilbur.space)>
* Copyright Year: 2017
* License: [MIT License](https://mit-license.org/)
* Version: [1.0.0-beta](http://semver.org/)

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

ASN.1 is used in, or required by, multiple technologies, including:

* [X.509 Certificates](http://www.itu.int/rec/T-REC-X.509-201610-I/en), used in [SSL/TLS](https://tools.ietf.org/html/rfc5246)
* [Lightweight Directory Access Protocol (LDAP)](https://www.ietf.org/rfc/rfc4511.txt)
* [X.500](http://www.itu.int/rec/T-REC-X.500-201610-I/en)
* The [magnetic stripes](https://www.iso.org/standard/43317.html) on credit cards and debit cards
* Microsoft's [Remote Desktop Protocol](https://msdn.microsoft.com/en-us/library/mt242409.aspx)
* [Simple Network Management Protocol (SNMP)](https://www.ietf.org/rfc/rfc1157.txt) 
* [Common Management Information Protocol (CMIP)](http://www.itu.int/rec/T-REC-X.711/en)
* [Signalling System Number 7 (SS7)](http://www.itu.int/rec/T-REC-Q.700-199303-I/en), used to make most phone calls on the Public Switched Telephone Network (PSTN).
* [H.323](http://www.itu.int/rec/T-REC-H.323-200912-I/en) Video conferencing
* Biometrics Protocols:
  * [BioAPI Interworking Protocol](https://www.iso.org/standard/43611.html)
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

- [ ] Properties for member `type`
  - [ ] `typeClass` (Just rename `tagClass`.)
  - [ ] `typeConstruction` (Just rename `construction`.)
  - [ ] `typeNumber`
- [ ] Command Line Tools
  - [ ] `encode-der`
  - [ ] `encode-ber`
  - [ ] `encode-cer`
  - [ ] `decode-der`
  - [ ] `decode-ber`
  - [ ] `decode-cer`
- [ ] Fuzz testing (Sending random bytes to a decoder to get something unexpected)
- [x] Test that all one-byte elements throw exceptions
- [ ] Cross-Platform Testing
  - [ ] Windows
  - [ ] Mac OS X
  - [ ] Linux
- [ ] Comparison Testing with
  - [ ] [PyASN1](http://pyasn1.sourceforge.net)
  - [ ] [@YuryStrozhevsky](https://github.com/YuryStrozhevsky)'s [ASN1 BER Codec](https://github.com/YuryStrozhevsky/C-plus-plus-ASN.1-2008-coder-decoder)
- [ ] Field Testing
  - [ ] Reading X.509 Certificates
  - [ ] Creating a Session with [OpenLDAP Server](http://www.openldap.org)
  - [ ] Do something with SNMP
  - [ ] Do something with H.323 Video conferencing
  - [ ] Do something with BIP Biometrics 
  - [ ] Do something with CBEFF Biometrics
  - [ ] Do something with ACBio Biometrics
  - [ ] [@YuryStrozhevsky](https://github.com/YuryStrozhevsky)'s [ASN1 Test Suite](https://github.com/YuryStrozhevsky/ASN1-2008-free-test-suite)
- [ ] Build Version Testing
  - [ ] `-noboundscheck`
- [ ] Review by one security firm
- [ ] Review for HeartBleed-like vulnerabilities
- [ ] Review of all ASN.1-related CVEs
- [ ] Review that character-encoded `REAL`s are strictly conformant to ISO 6093 (Maybe even make an ISO 6093 Library...)
- [ ] Indefinite-Length Encoding

### 1.0.0 Release

- [ ] Publish a [Dub package](https://code.dlang.org) for it
- [ ] Share it on [the Dlang Subreddit](https://www.reddit.com/r/dlang/)
- [ ] [Publish an RPM package](https://access.redhat.com/sites/default/files/attachments/rpm_building_howto.pdf)
- [ ] [Publish an APT package](https://debian-handbook.info/browse/stable/debian-packaging.html)
- [ ] Configure [Travis CI](https://travis-ci.org)
- [ ] Dynamically-linked libraries
- [ ] Create `man(1)` (executables) and `man(3)` (Library calls) pages
- [ ] Create Wikipedia pages for each codec

### 1.1.0 Release

The following codecs will be added:

- [ ] Aligned Packed Encoding Rules (PER)
- [ ] Unaligned Packed Encoding Rules (UPER)
- [ ] Canonical Packed Encoding Rules (CPER)
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

- [ ] JSON Encoding Rules (JER)
- [ ] XML Encoding Rules (XER)
- [ ] Canonical XML Encoding Rules (CXER)
- [ ] Extended XML Encoding Rules (EXER)
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

- [ ] Octet Encoding Rules (OER)
- [ ] Canonical Octet Encoding Rules (COER)
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

- [ ] Teletex (T61String) validation
- [ ] Videotex validation
- [ ] Included Source Signature
- [ ] Build System
  - [ ] [Bazel](https://www.bazel.build)
  - [ ] Makefile
  - [ ] Compiled D Executable
  - [ ] Support `gdc` and `ldc` compilation

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

[Ilya Tingof](https://stackoverflow.com/users/1175029/ilya-etingof) ([@etingof](https://github.com/etingof)), who answered several questions of mine on StackOverflow, and who authored [PyASN1](http://pyasn1.sourceforge.net/).

## See Also

* [X.680 - Abstract Syntax Notation One (ASN.1)](https://www.itu.int/rec/T-REC-X.680/en), published by the
[International Telecommunications Union](http://www.itu.int/en/pages/default.aspx).
* [X.690 - ASN.1 encoding rules](http://www.itu.int/rec/T-REC-X.690/en), published by the
[International Telecommunications Union](http://www.itu.int/en/pages/default.aspx).

## Contact Me

If you would like to suggest fixes or improvements on this library, please just
comment on this on GitHub. If you would like to contact me for other reasons,
please email me at [jonathan@wilbur.space](mailto:jonathan@wilbur.space). :boar: