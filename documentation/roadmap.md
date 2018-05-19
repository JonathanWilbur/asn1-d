# Development Roadmap

## 2.5.0 Release

- [x] Create "test" `GNU Make` target
- [x] Create an [MSI Installer](https://wixtoolset.org/)
- [x] Create a Mac OS X App Bundle + Disk Image
- [x] Create an [RPM package](https://access.redhat.com/sites/default/files/attachments/rpm_building_howto.pdf)
- [x] Create a [Debian package](https://debian-handbook.info/browse/stable/debian-packaging.html)
- [ ] Generate a `.def` file for Windows?
- [ ] Make tools build with the dynamically-linked library, if possible
- [ ] Create a Mac OS X Package file
- [ ] Refactor `toBytes` so that `lengthBytes` is broken off into a separate field.
- [ ] Publish a [Brew formula](https://docs.brew.sh/Formula-Cookbook.html)
  - [x] `install` command
  - [ ] `test` command
- [ ] Replace numbers with `enum`s in `ASN1TagNumberException` instantiations
- [ ] Figure out how to concatenate long exception strings or something, so exception constructors can be `@nogc`.
- [ ] Apply `@nogc` when possible
- [ ] Apply `pure` when possible
- [ ] Apply function attributes to code in command-line tools

## 2.6.0 Release

The following codecs will be added:

- [ ] [Basic Aligned Packed Encoding Rules (PER)](https://www.itu.int/rec/T-REC-X.691-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-per`
  - [ ] `decode-per`

After this release, developers will be able to use this library to develop a
Remote Desktop Protocol library.

## 2.7.0 Release

- [ ] [Canonical Aligned Packed Encoding Rules (CPER)](https://www.itu.int/rec/T-REC-X.691-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-cper`
  - [ ] `decode-cper`

## 2.8.0 Release

- [ ] [Basic Unaligned Packed Encoding Rules (UPER)](https://www.itu.int/rec/T-REC-X.691-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-uper`
  - [ ] `decode-uper`

## 2.9.0 Release

- [ ] [Canonical Unaligned Packed Encoding Rules (CUPER)](https://www.itu.int/rec/T-REC-X.691-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-cuper`
  - [ ] `decode-cuper`

## 2.10.0 Release

The following codecs will be added:

- [ ] [Octet Encoding Rules (OER)](https://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] [Canonical Octet Encoding Rules (COER)](https://www.itu.int/rec/T-REC-X.696-201508-I)
- [ ] Command-Line Tools
  - [ ] `encode-oer`
  - [ ] `encode-coer`
  - [ ] `decode-oer`
  - [ ] `decode-coer`

## 2.11.0 Release

- [ ] Lightweight Encoding Rules (LWER)
- [ ] Command-Line Tools
  - [ ] `encode-lwer`
  - [ ] `decode-lwer`

## 2.12.0 Release

- [ ] BACNet Encoding Rules
- [ ] Command-Line Tools
  - [ ] `encode-bacnet`
  - [ ] `decode-bacnet`

## 2.13.0 Release

The following codecs will be added:

- [ ] Signalling-specific Encoding Rules (SER)
- [ ] Command-Line Tools
  - [ ] `encode-ser`
  - [ ] `decode-ser`

## 3.0.0 Release

- [ ] Configure [Travis CI](https://travis-ci.org)
- [ ] Improve the Fuzz Testing Tool
- [ ] Achieve 100% Code Coverage
- [ ] Get rid of `opCast!(ubyte[])()`.
- [ ] TeletexString (T61String) validation (WireShark has an implementation.)
- [ ] VideotexString validation
- [ ] Operator Overloads
  - [ ] `~=` making a constructed element
- [ ] Build System
  - [ ] [Bazel](https://www.bazel.build)
  - [ ] Compiled D Executable
  - [ ] Support `gdc` and `ldc` compilation
- [ ] Add signatures with [my GPG key](https://jonathan.wilbur.space/downloads/jonathan@wilbur.space.gpg.pub)
- [ ] Create `man(3)` (Library calls) pages
- [ ] Unit tests based on examples from X.690
- [ ] Unit tests based on examples from the Dubuisson book
- [ ] Comparison tests to Go's ASN.1 library module
- [ ] Build testing
  - [ ] OpenSolaris
  - [ ] FreeBSD

## Unversioned

- [ ] Add `chroot` jails or containerization to each step of the build process
- [ ] Create Wikipedia pages for each codec
- [ ] Review by one security firm
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