# Development Roadmap

### 2.3.1 Release

- [x] Make command line tools decode all integers as `BigInt`

### 2.3.2 Release

- [x] Optimize `integer!BigInt`

### 2.3.3 Release

- [x] Add explanatory comments

### 2.3.4 Release

- [x] Change `body` to `do`, since `body` is being deprecated
- [x] Change `for` loops to `foreach` loops
- [x] Use `.length` pre-allocation instead of incremental appends via `~`

### 2.3.5 Release

- [x] Rewrite `objectIdentifier` accessor so it does not create a bunch of new arrays
- [x] Make command-line tools display decoded `BIT STRING`s as `bool` arrays
- [x] Make command-line tools display decoded `UniversalString`s and `BMPString`s.

### 2.3.6 Release

- [x] Use `Appender` for `SEQUENCE` and `SET`.

### 2.4.0 Release

- [x] New constructors
  - [x] `Element(ASN1Class, ASN1Construction, size_t)`

### 2.4.1 Release

- [x] Fix Improper OID encoding (leading zeros)

### 2.4.2 Release

- [ ] Figure out how to concatenate long exception strings or something, so exception constructors can be `@nogc`.
- [ ] Apply `@nogc` when possible
- [ ] Apply `pure` when possible
- [ ] Apply function attributes to code in command-line tools

### 2.6.0 Release

- [ ] Achieve 100% Code Coverage
- [ ] Publish an [RPM package](https://access.redhat.com/sites/default/files/attachments/rpm_building_howto.pdf)
- [ ] Publish an [Debian package](https://debian-handbook.info/browse/stable/debian-packaging.html)
- [x] Publish a [Brew package](https://docs.brew.sh/Formula-Cookbook.html)
  - [ ] `test` command
- [ ] Configure [Travis CI](https://travis-ci.org)
- [ ] Create an [MSI Installer](http://wixtoolset.org/)
- [ ] Create a Mac OS X Package file
- [x] Create a Mac OS X App Bundle + Disk Image
- [ ] Create `man(3)` (Library calls) pages
- [ ] Create Wikipedia pages for each codec
- [ ] Review by one security firm
- [ ] Add signatures with [my GPG key](https://jonathan.wilbur.space/downloads/jonathan@wilbur.space.gpg.pub)
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
- [ ] Unit tests based on examples from X.690
- [ ] Unit tests based on examples from the Dubuisson book
- [ ] Comparison tests to Go's ASN.1 library module
- [ ] Generate a `.def` file for Windows?
- [ ] Make tools build with the dynamically-linked library, if possible
- [ ] Build testing
  - [ ] OpenSolaris
  - [ ] FreeBSD
- [ ] Improved exception messages
- [ ] Improve the Fuzz Testing Tool
- [ ] Create "test" `GNU Make` target
- [ ] Code Formatting
  - [ ] Format `switch` statements
  - [ ] Replace numbers with `enum`s in `ASN1TagNumberException` instantiations

## 2.7.0 Release

The following codecs will be added:

- [ ] [Aligned Packed Encoding Rules (PER)](https://www.itu.int/rec/T-REC-X.691-201508-I)
- [ ] Unaligned Packed Encoding Rules (UPER)
- [ ] [Canonical Packed Encoding Rules (CPER)](https://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-per`
  - [ ] `encode-uper`
  - [ ] `encode-cper`
  - [ ] `decode-per`
  - [ ] `decode-uper`
  - [ ] `decode-cper`

After this release, developers will be able to use this library to develop a
Remote Desktop Protocol library.

## 2.8.0 Release

The following codecs will be added:

- [ ] [JSON Encoding Rules (JER)](https://www.itu.int/rec/T-REC-X.697-201710-P)
- [ ] [XML Encoding Rules (XER)](https://www.itu.int/rec/T-REC-X.693-201508-I/en)
- [ ] [Canonical XML Encoding Rules (CXER)](https://www.itu.int/rec/T-REC-X.693-201508-I/en)
- [ ] [Extended XML Encoding Rules (EXER)](https://www.itu.int/rec/T-REC-X.693-201508-I/en)
- [ ] Command-Line Tools
  - [ ] `encode-xer`
  - [ ] `encode-cxer`
  - [ ] `encode-exer`
  - [ ] `encode-jer`
  - [ ] `decode-xer`
  - [ ] `decode-cxer`
  - [ ] `decode-exer`
  - [ ] `decode-jer`

## 2.9.0 Release

The following codecs will be added:

- [ ] [Octet Encoding Rules (OER)](https://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] [Canonical Octet Encoding Rules (COER)](https://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-oer`
  - [ ] `encode-coer`
  - [ ] `decode-oer`
  - [ ] `decode-coer`

## 2.10.0 Release

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

## 3.0.0 Release

- [ ] Get rid of `opCast!(ubyte[])()`.
- [ ] TeletexString (T61String) validation (WireShark has an implementation.)
- [ ] VideotexString validation
- [ ] Operator Overloads
  - [ ] `~=` making a constructed element
- [ ] Build System
  - [ ] [Bazel](https://www.bazel.build)
  - [ ] Compiled D Executable
  - [ ] Support `gdc` and `ldc` compilation