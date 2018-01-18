# Development Roadmap

### 1.0.2 Release

- [x] Publish a [Dub package](https://code.dlang.org) for it

### 1.0.3 Release

- [ ] Code Formatting
  - [ ] Format `switch` statements
  - [ ] Replace numbers with `enum`s in `ASN1TagNumberException` instantiations

### 1.0.4 Release

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

## 1.1.0 Release

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

## 1.2.0 Release

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

## 1.3.0 Release

The following codecs will be added:

- [ ] [Octet Encoding Rules (OER)](http://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] [Canonical Octet Encoding Rules (COER)](http://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-oer`
  - [ ] `encode-coer`
  - [ ] `decode-oer`
  - [ ] `decode-coer`

## 1.4.0 Release

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

## 2.0.0 Release

- [ ] TeletexString (T61String) validation (WireShark has an implementation.)
- [ ] VideotexString validation
- [ ] Operator Overloads
  - [ ] `~=` making a constructed element
- [ ] Build System
  - [ ] [Bazel](https://www.bazel.build)
  - [ ] Makefile
  - [ ] Compiled D Executable
  - [ ] Support `gdc` and `ldc` compilation