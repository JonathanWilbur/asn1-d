# ASN.1 D Library

* Author: [Jonathan M. Wilbur](https://jonathan.wilbur.space) <[jonathan@wilbur.space](mailto:jonathan@wilbur.space)>
* Copyright Year: 2018
* License: [MIT License](https://mit-license.org/)
* Version: [2.1.3](https://semver.org/)

## What is ASN.1?

ASN.1 stands for *Abstract Syntax Notation*. ASN.1 was first specified in
[X.680 - Abstract Syntax Notation One (ASN.1)](https://www.itu.int/rec/T-REC-X.680/en),
by the [International Telecommunications Union](https://www.itu.int/en/pages/default.aspx).
ASN.1 messages can be encoded in one of several encoding/decoding standards.
It provides a system of types that are extensible, and can presumably describe
every protocol. You can think of it as a protocol for describing other protocols
as well as a family of standards for encoding and decoding said protocols.
It is similar to Google's [Protocol Buffers](https://developers.google.com/protocol-buffers/),
or Sun Microsystems' [External Data Representation (XDR)](https://tools.ietf.org/html/rfc1014).

For more information on what ASN.1 is, see `documentation/asn1.md`.

## Why ASN.1?

ASN.1 is used in, or required by, multiple technologies, including:

* [X.509 Certificates](https://www.itu.int/rec/T-REC-X.509-201610-I/en), used in [SSL/TLS](https://tools.ietf.org/html/rfc5246)
* [Lightweight Directory Access Protocol (LDAP)](https://www.ietf.org/rfc/rfc4511.txt)
* [X.400](https://www.itu.int/rec/T-REC-X.400/en), the messaging system used by the U.S. Military
* [X.500](https://www.itu.int/rec/T-REC-X.500-201610-I/en)
* The [magnetic stripes](https://www.iso.org/standard/43317.html) on credit cards and debit cards
* Microsoft's [Remote Desktop Protocol (RDP)](https://msdn.microsoft.com/en-us/library/mt242409.aspx)
* [Simple Network Management Protocol (SNMP)](https://www.ietf.org/rfc/rfc1157.txt)
* [Common Management Information Protocol (CMIP)](https://www.itu.int/rec/T-REC-X.711/en)
* [Signalling System Number 7 (SS7)](https://www.itu.int/rec/T-REC-Q.700-199303-I/en),
  used to make most phone calls on the Public Switched Telephone Network (PSTN).
* [Kerberos 5](https://tools.ietf.org/html/rfc4120)
* [H.323](https://www.itu.int/rec/T-REC-H.323-200912-I/en) Video conferencing
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

This list can also be found in `documentation/asn1.d`.

## Why *This* Library?

You should use *this* library, because ASN.1 is _really_ difficult to implement,
and ASN.1 is _really_ _really_ difficult to implement **to specification**, and
ASN.1 is _really_ _really_ _really_ difficult to implement **securely**. I spent
at least over 1000 hours in 2017 working on this library to make sure it is
implemented to specification and implemented securely. This library has been
subjected to about 4.3 billion random inputs on Windows, Mac OS X, and Linux,
as well as over 100,000 unit tests. I have also reviewed _all_ CVE's from the
[National Institute of Standards and Technology](https://www.nist.gov/)'s
[National Vulnerability Database](https://nvd.nist.gov/) that are related to
ASN.1 and related codecs. Further, I documented this library so well that,
unlike so many other libraries out there, you should not need to look at the
source code--the included documentation and the generated HTML documentation
should be sufficient. This library is **unambiguously** the best ASN.1 library
in any programming language **ever**.

I will repeat myself: **I do not recommend that you implement your own ASN.1 library**,
but if you are still considering it, please first:

1. Let me know why. If you have good ideas, I will be more than happy to implement
them in this library.
1. Let me know where I can find your library. I will constructively criticize it
with such ferocity that, if your ancestors live to tell the tale, they will do so
for millenia to come. **I guarantee you** that you will screw up and leave a
security vulnerability in your code if you aren't just copying and pasting from my code.

## Building and Installing

There are four scripts in `build/scripts` that help you build this library,
in addition to building using `dub`. If you are using Windows, you can build
by running `.\build\scripts\build.ps1` from PowerShell, or `.\build\scripts\build.bat`
from the traditional `cmd` shell. If you are on any POSIX-compliant(-ish)
operating system, such as Linux or Mac OS X, you may build this library using
`./build/scripts/build.sh` or `make -f ./build/scripts/posix.make`. The output
library will be in `./build/libraries`. The command-line tools will be in
`./build/executables`.

For more information on building and installing, see `documentation/install.md`.

## Library Usage

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

For more information on usage of the library, see `documentation/library.md`,
`documentation/security.md`, `documentation/concurrency.md`. After that, see
the compiler-generated HTML documentation in `documentation/html` for even
more detail.

## Command-Line Tools Usage

This library also provides for a pair of command-line tools for each set
of encoding rules. The following can be used as a way to read the
Distinguished Encoding Rules (DER) structure of an X.509 PEM certificate,
for instance:

```bash
tail -n +2 example.pem | head -n -1 | base64 --decode | decode-der
```

For more information on usage of the command-line tools, see
`documentation/tools.md`, or if you are using a POSIX-compliant(-ish)
system, run `sudo make -f build/scripts/posix.make install` to install
the `man` pages, then view them by running `man decode-der`, for instance.

## Development

Version 1.0.0 was released on January 12th, 2018. For a list of all past
releases, see `documentation/releases.csv`. For the plans for future releases,
see `documentation/roadmap.md`. If you would like to contribute (and please do),
please see `documentation/contributing.md`.

## Bugs

The codecs are intended to be `final` classes, but due to
[this bug](https://issues.dlang.org/show_bug.cgi?id=17909) I found, it cannot
be until that bug is resolved.

## Special Thanks

* [Ilya Tingof](https://stackoverflow.com/users/1175029/ilya-etingof) ([@etingof](https://github.com/etingof)), who answered several questions of mine on StackOverflow, and who authored [PyASN1](https://pyasn1.sourceforge.net/).
* [@YuryStrozhevsky](https://github.com/YuryStrozhevsky) for his [ASN.1 BER Codec](https://github.com/YuryStrozhevsky/C-plus-plus-ASN.1-2008-coder-decoder) and his [@YuryStrozhevsky](https://github.com/YuryStrozhevsky)'s [ASN.1 Test Suite](https://github.com/YuryStrozhevsky/ASN1-2008-free-test-suite)

## See Also

* [X.680 - Abstract Syntax Notation One (ASN.1)](https://www.itu.int/rec/T-REC-X.680/en), published by the
[International Telecommunications Union](https://www.itu.int/en/pages/default.aspx).
* [X.690 - ASN.1 encoding rules](https://www.itu.int/rec/T-REC-X.690/en), published by the
[International Telecommunications Union](https://www.itu.int/en/pages/default.aspx).
* [ASN.1: Communication Between Heterogeneous Systems](https://www.oss.com/asn1/resources/books-whitepapers-pubs/dubuisson-asn1-book.PDF) by Olivier Dubuisson

## Contact Me

If you would like to suggest fixes or improvements on this library, please just
[leave an issue on this GitHub page](https://github.com/JonathanWilbur/asn1-d/issues). If you would like to contact me for other reasons,
please email me at [jonathan@wilbur.space](mailto:jonathan@wilbur.space)
([My GPG Key](https://jonathan.wilbur.space/downloads/jonathan@wilbur.space.gpg.pub))
([My TLS Certificate](https://jonathan.wilbur.space/downloads/jonathan@wilbur.space.chain.pem)). :boar: