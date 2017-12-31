# Development Roadmap

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

- [ ] Teletex (T61String) validation (WireShark has an implementation.)
- [ ] Videotex validation
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