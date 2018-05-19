Summary: Libraries and Tools for encoding and decoding ASN.1 data
Name: asn1
Version: 2.4.3
Release: 1
Group: D Development Tools and Libraries
License: MIT
Url: https://github.com/JonathanWilbur/asn1-d
Source: https://github.com/JonathanWilbur/asn1-d/archive/v%{version}.tar.gz
Packager: Jonathan M. Wilbur <jonathan@wilbur.space>

%description
Library and executables for ASN.1 encoding and decoding using BER, CER, and
DER codecs, all written in the D programming language.

%prep
tar -xf $RPM_SOURCE_DIR/v%{version}.tar.gz -C $RPM_BUILD_DIR

%build
make --makefile=$RPM_BUILD_DIR/asn1-d-%{version}/build/posix.make root=$RPM_BUILD_DIR/asn1-d-%{version}

%install
make --makefile=$RPM_BUILD_DIR/asn1-d-%{version}/build/posix.make install root=$RPM_BUILD_DIR/asn1-d-%{version}

%check
make --makefile=$RPM_BUILD_DIR/asn1-d-%{version}/build/posix.make test root=$RPM_BUILD_DIR/asn1-d-%{version}

%clean
make --makefile=$RPM_BUILD_DIR/asn1-d-%{version}/build/posix.make clean root=$RPM_BUILD_DIR/asn1-d-%{version}

%files
output/libraries/asn1-%{version}.so
output/libraries/asn1-%{version}.a
output/executables/encode-ber
output/executables/encode-cer
output/executables/encode-der
output/executables/decode-ber
output/executables/decode-cer
output/executables/decode-der

%doc
documentation/asn1.md
documentation/compliance.md
documentation/concurrency.md
documentation/contributing.md
documentation/credits.csv
documentation/design.md
documentation/install.md
documentation/library.md
documentation/mit.license
documentation/releases.csv
documentation/roadmap.md
documentation/security.md
documentation/tools.md
documentation/links/asn1-playground.uri