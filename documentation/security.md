# ASN.1 D Library Security Review

## Security Review by A Security Firm

I would like to get an actual security firm to review this code for free, which
I recognize is probably not going to happen. If I can't get one for free, I 
would at least like to get a price quote, so I could start a crowdfunding
campaign

## Field Testing

### Decode an X.509 Certificate

This worked perfectly on the first try. Nothing to report.

### Perform a handshake with an OpenLDAP server

Obviously, this one was a little more involved, but I only had trouble because
I was creating incorrect PDUs. Once I got that fixed, it worked fine.

### Test against all OpenSSL d2i Tests

This threw exceptions where it should have and did not when it should not have.
A success.

## Fuzz Testing

### FourBytes Fuzz Testing

FourBytes is a rather uncreative name I gave to the fuzz test that supplies
all possible combinations of four bytes (4.2 billion of them) to the 
constructors of each codec. I found two critical bugs from the testing, which
are described below. So as of now, all four-byte combinations are safe to 
decode. (Not a promise; please don't sue me.)

#### Bug #1

An "off-by-one" error. When using definite-short length, I did not check that
the remaining bytes of the encoded data was just one byte short of what was
necessary to live up to the stated length in the length octets. In other words,
I used `>` when I should have used `>=`.

#### Bug #2

I did not check that the value octets of an indefinite-length element were
greater than or equal to two in number, so an indefinite-length element with
a single null value octet (`0x00u`) would read out of bounds.

### ThreeBytes Fuzz Testing

No bugs found.

### TwoBytes Fuzz Testing

No bugs found.

## CVE Review

Below are my reviews of all ASN.1-related CVEs, and how they might relate to 
my ASN.1 Library. If they are relevant, I detail what actions I will take or
have taken.

_Note: "Ethereal" referenced in the early 2000s CVEs below refers to the old_
_name for WireShark._

### CVE-2017-11496

> Stack buffer overflow in hasplms in Gemalto ACC (Admin Control Center), all 
> versions ranging from HASP SRM 2.10 to Sentinel LDK 7.50, allows remote 
> attackers to execute arbitrary code via malformed ASN.1 streams in V2C and 
> similar input files.

Closed source. Skipping.

### CVE-2017-9023

> The ASN.1 parser in strongSwan before 5.5.3 improperly handles `CHOICE` types 
> when the x509 plugin is enabled, which allows remote attackers to cause a 
> denial of service (infinite loop) via a crafted certificate.

From [StrongSwan's own website](
        https://strongswan.org/blog/2017/05/30/strongswan-vulnerability-(cve-2017-9023).html):

> Several extensions in X.509 certificates use `CHOICE` types to allow exactly 
> one of several possible sub-elements. An extension that's defined like this, 
> which strongSwan always supported, is `CRLDistributionPoints`, where the 
> optional `distributionPoint` is defined as follows:

```asn1
DistributionPointName ::= CHOICE {
    fullName                [0]     GeneralNames,
    nameRelativeToCRLIssuer [1]     RelativeDistinguishedName }
```

> So it may either be a `GeneralName` or an `RelativeDistinguishedName` but not 
> both and one of them must be present if there is a `distributionPoint`. So 
> far the x509 plugin and ASN.1 parser treated the choices simply as optional 
> elements inside of a loop, without enforcing that exactly one of them was 
> parsed (or that any of them were matched). This lead to the issue that if 
> none of the options were found the parser was stuck in an infinite loop. 
> Other extensions that are affected are `ipAddrBlocks` (supported since 4.3.6) 
> and `CertificatePolicies` (since 4.5.1).

This concrete issue does not affect this library, but the implementations for 
`EXTERNAL`, `EmbeddedPDV`, and `CharacterString` need to be reviewed and 
tested for this vulnerability.

This did actually result in me finding a bug in the Basic Encoding Rules encoding
of `EXTERNAL`. I mixed up `&&` and `||`, resulting in a conditional in which
an exception would be thrown only if _all_ of the tags of the `EXTERNAL` were
incorrect.

### CVE-2016-7053

Note: CMS = [Cryptographic Message Syntax](https://tools.ietf.org/html/rfc5652)

> In OpenSSL 1.1.0 before 1.1.0c, applications parsing invalid CMS structures 
> can crash with a `NULL` pointer dereference. This is caused by a bug in the 
> handling of the ASN.1 `CHOICE` type in OpenSSL 1.1.0 which can result in a 
> `NULL` value being passed to the structure callback if an attempt is made to 
> free certain invalid encodings. Only `CHOICE` structures using a callback 
> which do not handle `NULL` value are affected.

Reviewed:
[OpenSSL's Test for this vulnerability](
        https://github.com/openssl/openssl/blob/6a69e8694af23dae1d1927813932f4296d133416/test/recipes/25-test_d2i.t) 
as well as 
[OpenSSL version 1.1.0](
        https://github.com/openssl/openssl/blob/OpenSSL_1_1_0-stable/apps/cms.c).

Looking at the `bad-cms.der` file that caused this exception, I do not 
believe this one is a problem. I decoded `bad-cms.der` without a problem
(it did throw an exception, but that was _supposed_ to happen). Looking at
that file, this appears to be a failure to validate length. That's it.

### CVE-2016-6129

> The `rsa_verify_hash_ex` function in `rsa_verify_hash.c` in LibTomCrypt, as 
> used in OP-TEE before 2.2.0, does not validate that the message length is 
> equal to the ASN.1 encoded data length, which makes it easier for remote 
> attackers to forge RSA signatures or public certificates by leveraging a 
> Bleichenbacher signature forgery attack.

The answer is really simple: make sure the encoded length is equal to the 
actual length of the encoded data.

### CVE-2016-9939

> Crypto++ (aka cryptopp and libcrypto++) 5.6.4 contained a bug in its ASN.1 
> BER decoding routine. The library will allocate a memory block based on the 
> length field of the ASN.1 object. If there is not enough content octets in 
> the ASN.1 object, then the function will fail and the memory block will be 
> zeroed even if its unused. There is a noticeable delay during the wipe for a 
> large allocation.

Does not apply, because the memory allocation is handled by the runtime.

### CVE-2016-6891

> MatrixSSL before 3.8.6 allows remote attackers to cause a denial of service 
> (out-of-bounds read) via a crafted ASN.1 Bit Field primitive in an X.509 
> certificate.

The [CHANGES.md](
        https://github.com/matrixssl/matrixssl/blob/3-8-6-open/CHANGES.md) 
leaves a note about this issue:

> Critical parsing bug for X.509 certificates Security Researcher Craig Young 
> reported two issues related to X.509 certificate parsing. An error in 
> parsing a maliciously formatted Subject Alt Name field in a certificate could 
> cause a crash due to a write beyond buffer and subsequent free of an 
> unallocated block of memory. An error in parsing a maliciously formatted 
> ASN.1 Bit Field primitive could cause a crash due to a memory read beyond 
> allocated memory.

There is almost no information on where this bug is in the source code. I cannot find any significant changes to `subjectAltName` parsing between MatrixSSL versions 3.8.4 and 3.8.6.

### CVE-2016-5080

> Integer overflow in the `rtxMemHeapAlloc` function in asn1rt_a.lib in 
> Objective Systems ASN1C for C/C++ before 7.0.2 allows context-dependent 
> attackers to execute arbitrary code or cause a denial of service 
> (heap-based buffer overflow), on a system running an application compiled by 
> ASN1C, via crafted ASN.1 data.

Closed source software. Skipping.

### CVE-2016-0758

> Integer overflow in `lib/asn1_decoder.c` in the Linux kernel before 4.6 
> allows local users to gain privileges via crafted ASN.1 data.

[Linux Diff](
        https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=23c8a812dc3c621009e4f0e5342aa4e2ede1ceaa).

This is another integer overflow when parsing length.

- [x] Ensure the length value cannot overflow or underflow.

### CVE-2015-5726

> The BER decoder in Botan 0.10.x before 1.10.10 and 1.11.x before 1.11.19 
> allows remote attackers to cause a denial of service (application crash) via 
> an empty `BIT STRING` in ASN.1 data.

From the [Botan Security Advisory](https://botan.randombit.net/security.html):

> The BER decoder would crash due to reading from offset 0 of an empty vector 
> if it encountered a `BIT STRING` which did not contain any data at all. This 
> can be used to easily crash applications reading untrusted ASN.1 data, but 
> does not seem exploitable for code execution.

They did not validate that the `BIT STRING` in question has at least one byte.

- [x] Write unit tests to ensure that all `BIT STRING`s throw if length < 3.

~~Really, I want to write unit tests that test all combinations of two bytes for
every type that requires at least three to make sure that they throw exceptions.~~ Done.

### CVE-2016-2176

> The `X509_NAME_oneline` function in `crypto/x509/x509_obj.c` in OpenSSL 
> before 1.0.1t and 1.0.2 before 1.0.2h allows remote attackers to obtain 
> sensitive information from process stack memory or cause a denial of service 
> (buffer over-read) via crafted EBCDIC ASN.1 data.

The [fixing commit](
        https://git.openssl.org/?p=openssl.git;a=commit;h=2919516136a4227d9e6d8f2fe66ef976aaf8c561) 
reads:

> ASN1 Strings that are over 1024 bytes can cause an overread in applications 
> using the `X509_NAME_oneline()` function on EBCDIC systems. This could result 
> in arbitrary stack data being returned in the buffer.

The commit diff does not show it, but that's because the EBCDIC buffer is fixed 
at 1024 `char`s:

```c
char ebcdic_buf[1024];
```

Having said that, the diff reads:

```diff
-            ascii2ebcdic(ebcdic_buf, q, (num > sizeof ebcdic_buf)
-                         ? sizeof ebcdic_buf : num);
+            if (num > (int)sizeof(ebcdic_buf))
+                num = sizeof(ebcdic_buf);
+            ascii2ebcdic(ebcdic_buf, q, num);
```

Basically, what the code above is doing is truncating the input from `q` into 
`ebcdic_buf` to the number of bytes indicated in the third argument to 
`ascii2ebcdic`. However, the the length of the data in the buffer still needs
to be used later in the code. In the earlier version of the code, the correct
amount of bytes are copied into `ebcdic_buf`, but `num` is still a value 
greater than 1024, meaning that the subsequent code will read `num` bytes 
from the buffer that is supposed to max out at 1024 bytes.

I don't think there is a lesson to learn here. This was just plain stupid.
Maybe if the developers did not give their variables stupid ambiguous names
like `num`, maybe they would be able to keep track of the significance of their
variables one hundred lines South of where they are declared.

### CVE-2016-2109

> The `asn1_d2i_read_bio` function in `crypto/asn1/a_d2i_fp.c` in the ASN.1 
> `BIO` implementation in OpenSSL before 1.0.1t and 1.0.2 before 1.0.2h allows 
> remote attackers to cause a denial of service (memory consumption) via a 
> short invalid encoding.

This [git commit](
        https://git.openssl.org/?p=openssl.git;a=commitdiff;h=c62981390d6cf9e3d612c489b8b77c2913b25807;hp=ddc606c914e72e770dbe8293a65585b7c3017bba) 
description describes the problem by describing the solution:

> If the ASN.1 BIO is presented with a large length field read it in chunks of 
> increasing size checking for EOF on each read. This prevents small files 
> allocating excessive amounts of data.

This one pretty much speaks for itself, but it is definitely worth reviewing my
code for potential denial-of-service conditions like this.

- [x] Review `.length = *` for potential memory consumption DoS attacks.
- [x] Try to exhaust memory by supplying the decoder with "false giants."

### CVE-2016-2108

> The ASN.1 implementation in OpenSSL before 1.0.1o and 1.0.2 before 1.0.2c 
> allows remote attackers to execute arbitrary code or cause a denial of 
> service (buffer underflow and memory corruption) via an `ANY` field in 
> crafted serialized data, aka the "negative zero" issue.

The [fixing git commit](
        https://git.openssl.org/?p=openssl.git;a=commitdiff;h=3661bb4e7934668bd99ca777ea8b30eedfafa871;hp=e697a4c3d7d2267e9d82d88dbfa5084475794cb3)
describes the problem like so:

> Fix bug where `i2c_ASN1_INTEGER` mishandles zero if it is marked as negative.

I am having a hard time understanding how this bug comes about, not in the 
least due to the abundance of meaningless variable names that litter the source
of OpenSSL. But nevertheless, I don't think there should be any problems with
my code encountering "negative zero," because, unlike this dumbass boomer code,
my code does not break off the state of the encoded data into a separate 
variable that is liable to deviate from the state of the encoded data.

But it would be worth a review.

- [x] Aggressively test all variations of encoding zero.

### CVE-2016-2053

> The `asn1_ber_decoder` function in `lib/asn1_decoder.c` in the Linux kernel 
> before 4.3 allows attackers to cause a denial of service (panic) via an ASN.1 
> BER file that lacks a public key, leading to mishandling by the 
> `public_key_verify_signature` function in 
> `crypto/asymmetric_keys/public_key.c`.

This does not really apply to my code, because my code does not parse ASN.1
data structures, per se, but rather, just parses the encoded data for a single
element. The ASN.1 implementation in the Linux Kernel operates on an entirely
different principle than my codec.

### CVE-2016-4421

> `epan/dissectors/packet-ber.c` in the ASN.1 BER dissector in Wireshark 1.12.x
> before 1.12.10 and 2.x before 2.0.2 allows remote attackers to cause a denial 
> of service (deep recursion, stack consumption, and application crash) via a 
> packet that specifies deeply nested data.

Again, I don't believe this applies to this library, because this library 
performs no recursion. Developers who use this library will perform recursion.
However, I will include a note to developers.

### CVE-2016-4418

> `epan/dissectors/packet-ber.c` in the ASN.1 BER dissector in Wireshark 1.12.x 
> before 1.12.10 and 2.x before 2.0.2 allows remote attackers to cause a denial 
> of service (buffer over-read and application crash) via a crafted packet that 
> triggers an empty set.

This is a problem with parsing ASN.1, rather than encoding or decoding. So this 
entirely does not apply to my library.

### CVE-2016-1950

> Heap-based buffer overflow in Mozilla Network Security Services (NSS) before 
> 3.19.2.3 and 3.20.x and 3.21.x before 3.21.1, as used in Mozilla Firefox 
> before 45.0 and Firefox ESR 38.x before 38.7, allows remote attackers to 
> execute arbitrary code via crafted ASN.1 data in an X.509 certificate.

The problem appears to be that the developers overwrite the `len` member of a 
`struct` representing an ASN.1 element, which normally represents the number
of bytes of encoded data, with the length in _bits_ of encoded data. Later on,
when the length field is used with the assumption that it still refers to 
bytes, which causes all kinds of errors. Further, the conversion from bits to
bytes and vice versa introduces problems with overflow as well.

On the [Bugzilla page](https://bugzilla.mozilla.org/show_bug.cgi?id=1245528), 
David Keeler comments:

> Ryan, this is another ASN.1 decoding bug, this time with `BIT STRING`. I had 
> a quick look at the history of changes around where the bug is, and unless 
> I'm missing some context, this has been present since it was written (or at 
> least imported into mercurial).
>
> Basically, `sec_asn1d_parse_leaf` wasn't treating the length of the output 
> `SECItem` for `BIT STRING`s as bits, so it would write past the end of 
> allocated memory. At the same time, the bytes-to-bits conversion in 
> `sec_asn1d_parse_more_bit_string` was unnecessary (and indeed, incorrect).

It looks like this code only gets triggered when the decoder encounters a 
constructed `BIT STRING`, which, in the case of an X.509 certificate, occurs in 
the `subjectPublicKey` and `signatureValue` fields. (There are probably more;
those are just the ones that I know of.) The out-of-bounds memory access occurs 
when the substrings of the constructed `BIT STRING` are finally assembled into 
a single `BIT STRING`.

This does not really relate to my code, since my code does not assemble 
substrings (although, I _might_ change that), but if it did, I would _never_
give `length` a precarious double-meaning that it was given by the developers
that wrote this terrible code.

### CVE-2016-2842

> The `doapr_outch` function in `crypto/bio/b_print.c` in OpenSSL 1.0.1 before 
> 1.0.1s and 1.0.2 before 1.0.2g does not verify that a certain memory 
> allocation succeeds, which allows remote attackers to cause a denial of 
> service (out-of-bounds write or memory consumption) or possibly have 
> unspecified other impact via a long string, as demonstrated by a large amount 
> of ASN.1 data, a different vulnerability than CVE-2016-0799.

As this 
[diff](
        https://git.openssl.org/?p=openssl.git;a=commitdiff;h=578b956fe741bf8e84055547b1e83c28dd902c73;hp=259b664f950c2ba66fbf4b0fe5281327904ead21) 
shows: this was fixed by giving `doapr_outch` an `int` return value, with 0 
indicating success. Else where in the code, you have changes like this: 

```diff
+                if(!doapr_outch(sbuffer, buffer, &currlen, maxlen, ch))
+                    return 0;
```

As noted in the description:

> Additionally the internal |doapr_outch| function can attempt to write to
> an OOB memory location (at an offset from the `NULL` pointer) in the event of
> a memory allocation failure. In 1.0.2 and below this could be caused where
> the size of a buffer to be allocated is greater than `INT_MAX`. E.g. this
> could be in processing a very long "%s" format string. Memory leaks can also
> occur.

Though I don't manually manage memory in D, it would be a wise idea to:

- [x] Test gigantic elements, where `.length` is `int.max` or larger.

### CVE-2016-0799

> The `fmtstr` function in `crypto/bio/b_print.c` in OpenSSL 1.0.1 before 
> 1.0.1s and 1.0.2 before 1.0.2g improperly calculates string lengths, which 
> allows remote attackers to cause a denial of service (overflow and 
> out-of-bounds read) or possibly have unspecified other impact via a long 
> string, as demonstrated by a large amount of ASN.1 data, a different 
> vulnerability than CVE-2016-2842.

It looks like this issue was fixed by this part of the
[diff](
        https://git.openssl.org/?p=openssl.git;a=commitdiff;h=578b956fe741bf8e84055547b1e83c28dd902c73;hp=259b664f950c2ba66fbf4b0fe5281327904ead21):

```diff
-    int padlen, strln;
+    int padlen;
+    size_t strln;
     int cnt = 0;
 
     if (value == 0)
         value = "<NULL>";
-    for (strln = 0; value[strln]; ++strln) ;
+
+    strln = strlen(value);
+    if (strln > INT_MAX)
+        strln = INT_MAX;
+
     padlen = min - strln;
-    if (padlen < 0)
+    if (min < 0 || padlen < 0)
         padlen = 0;
```

You can see that `strln` used to be an `int`. They changed this, because
if a supplied string contained greater than `INT_MAX` bytes, it would overflow
and become a `INT_MIN` (a negative number). When calculating `padlen`, 
subtracting a negative number from `min` gives an even larger number for 
`padlen`, which is used to calculate how many trailing spaces to append to the
formatted string. This can be leveraged to produce giant demands on memory.

Once again, this means that I need to:

- [x] Test gigantic elements, where `.length` is `int.max` or larger.

### CVE-2016-2522

> The `dissect_ber_constrained_bitstring` function in 
> `epan/dissectors/packet-ber.c` in the ASN.1 BER dissector in Wireshark 2.0.x 
> before 2.0.2 does not verify that a certain length is nonzero, which allows 
> remote attackers to cause a denial of service (out-of-bounds read and 
> application crash) via a crafted packet.

This one is really straight-forward. A `BIT STRING` must always have at least 
one byte of encoded data. The code here did not check that this first byte
exists before attempting to access it, thereby reading out of bounds.

- [x] Throw an exception if a `BIT STRING` does not have at least one byte.
- [x] Create unittests for the minimum size of all types.

### CVE-2015-7540

> The LDAP server in the AD domain controller in Samba 4.x before 4.1.22 does 
> not check return values to ensure successful ASN.1 memory allocation, which 
> allows remote attackers to cause a denial of service (memory consumption and 
> daemon crash) via crafted packets.

This one is also really straight-forward: they did not handle errors in 
allocating memory. The end.

### CVE-2015-7061

> The ASN.1 decoder in Apple OS X before 10.11.2, tvOS before 9.1, and watchOS 
> before 2.1 allows remote attackers to execute arbitrary code or cause a 
> denial of service (memory corruption) via a crafted certificate, a different 
> vulnerability than CVE-2015-7059 and CVE-2015-7060.

This one cannot really be reviewed, since Apple's code is closed-source.

### CVE-2015-7060

Ditto

### CVE-2015-7059

Ditto

### CVE-2015-3194

> `crypto/rsa/rsa_ameth.c` in OpenSSL 1.0.1 before 1.0.1q and 1.0.2 before 
> 1.0.2e allows remote attackers to cause a denial of service (`NULL` pointer 
> dereference and application crash) via an RSA PSS ASN.1 signature that lacks 
> a mask generation function parameter.

This one is really simple:

```diff
-    if (alg == NULL)
+    if (alg == NULL || alg->parameter == NULL)
         return NULL;
```

Though this library has nothing to do with RSA key exchange, problems with null
pointers could still happen. A review of the context-switching types should be
sufficient.

### CVE-2015-7182

> Heap-based buffer overflow in the ASN.1 decoder in Mozilla Network Security 
> Services (NSS) before 3.19.2.1 and 3.20.x before 3.20.1, as used in Firefox 
> before 42.0 and Firefox ESR 38.x before 38.4 and other products, allows 
> remote attackers to cause a denial of service (application crash) or possibly 
> execute arbitrary code via crafted OCTET STRING data.

The [Bugzilla page](https://bugzilla.mozilla.org/show_bug.cgi?id=1202868)'s 
title is descriptive enough:

> ASN.1 decoder heap overflow when decoding constructed OCTET STRING that 
> mixes indefinite and definite length encodings

This one is irrelevant to my library, because my library does not recurse 
(decode elements within other elements automatically). However, this may
change in future versions. For now, I do not have to do anything about this,
but it would be a good idea to leave a note for developers, and to keep this
in mind if I ever do decide to recursively decode.

### CVE-2015-1790

> The `PKCS7_dataDecodefunction` in `crypto/pkcs7/pk7_doit.c` in OpenSSL before 
> 0.9.8zg, 1.0.0 before 1.0.0s, 1.0.1 before 1.0.1n, and 1.0.2 before 1.0.2b 
> allows remote attackers to cause a denial of service (`NULL` pointer 
> dereference and application crash) via a PKCS#7 blob that uses ASN.1 encoding 
> and lacks inner `EncryptedContent` data.

This is a result of not checking that a pointer is null. This does not really
have any implications for my library. Moving on.

### CVE-2015-0289

> The PKCS#7 implementation in OpenSSL before 0.9.8zf, 1.0.0 before 1.0.0r, 
> 1.0.1 before 1.0.1m, and 1.0.2 before 1.0.2a does not properly handle a lack 
> of outer `ContentInfo`, which allows attackers to cause a denial of service 
> (`NULL` pointer dereference and application crash) by leveraging an 
> application that processes arbitrary PKCS#7 data and providing malformed data 
> with ASN.1 encoding, related to `crypto/pkcs7/pk7_doit.c` and 
> `crypto/pkcs7/pk7_lib.c`.

Ditto.

### CVE-2015-0287

> The `ASN1_item_ex_d2i` function in `crypto/asn1/tasn_dec.c` in OpenSSL before 
> 0.9.8zf, 1.0.0 before 1.0.0r, 1.0.1 before 1.0.1m, and 1.0.2 before 1.0.2a 
> does not reinitialize `CHOICE` and `ADB` data structures, which might allow 
> attackers to cause a denial of service (invalid write operation and memory 
> corruption) by leveraging an application that relies on ASN.1 structure 
> reuse.

I don't entirely understand this bug, but it sounds like the developers just 
did not check that a pointer is not null. Nothing for me to do about this.

### CVE-2015-0208

> The ASN.1 signature-verification implementation in the `rsa_item_verify` 
> function in `crypto/rsa/rsa_ameth.c` in OpenSSL 1.0.2 before 1.0.2a allows 
> remote attackers to cause a denial of service (`NULL` pointer dereference and 
> application crash) via crafted RSA PSS parameters to an endpoint that uses 
> the certificate-verification feature.

Once again, just reviewing the context-switching types should be sufficient.

### CVE-2015-1182

> The `asn1_get_sequence_of` function in `library/asn1parse.c` in PolarSSL 1.0 
> through 1.2.12 and 1.3.x through 1.3.9 does not properly initialize a pointer 
> in the `asn1_sequence` linked list, which allows remote attackers to cause a 
> denial of service (crash) or possibly execute arbitrary code via a crafted 
> ASN.1 sequence in a certificate.

The problem here is that PolarSSL does zero out the bytes of the buffer where 
the next item in the `SEQUENCE` is going to go, so when it is allocated, it is
allocated with fields pre-filled with junk data.

I don't think this will be relevant for my library, since I don't manually
initialize pointers, so I won't need to `memset` anything.

- [ ] Ensure that any members of any classes or structs start off with their 
        `.init` values.

### CVE-2014-1569

> The `definite_length_decoder` function in `lib/util/quickder.c` in Mozilla 
> Network Security Services (NSS) before 3.16.2.4 and 3.17.x before 3.17.3 does 
> not ensure that the DER encoding of an ASN.1 length is properly formed, which 
> allows remote attackers to conduct data-smuggling attacks by using a long 
> byte sequence for an encoding, as demonstrated by the 
> `SEC_QuickDERDecodeItem` function's improper handling of an arbitrary-length 
> encoding of `0x00`.

Review this [bug page](https://bugzilla.mozilla.org/show_bug.cgi?id=1064670).

`integer` and `enum` already check for this, but it might not hurt to look into
additional measures to ensure that DER does not encode invalid-length data.

- [x] Ensure there are no leading `NULL` bytes in DER Codec for `INTEGER` and 
        `ENUMERATED`
~~Ensure all padding bits in `BIT STRING` are zeroed.~~ Moved to `README.md`.

_Note: According to the Bugzilla page, it looks like some old X.509_
_certificates are not technically DER-compliant: they often pad their_
_`INTEGER`s._

### CVE-2014-4443

> Apple OS X before 10.10 allows remote attackers to cause a denial of service 
> (`NULL` pointer dereference) via crafted ASN.1 data.

Not really able to be reviewed, because Apple is closed-source.

### CVE-2014-1568

> Mozilla Network Security Services (NSS) before 3.16.2.1, 3.16.x before 
> 3.16.5, and 3.17.x before 3.17.1, as used in Mozilla Firefox before 32.0.3, 
> Mozilla Firefox ESR 24.x before 24.8.1 and 31.x before 31.1.1, Mozilla 
> Thunderbird before 24.8.1 and 31.x before 31.1.2, Mozilla SeaMonkey before 
> 2.29.1, Google Chrome before 37.0.2062.124 on Windows and OS X, and Google 
> Chrome OS before 37.0.2062.120, does not properly parse ASN.1 values in X.509 
> certificates, which makes it easier for remote attackers to spoof RSA 
> signatures via a crafted certificate, aka a "signature malleability" issue.

[This bugzilla](https://bugzilla.mozilla.org/show_bug.cgi?id=1064636)
[That bugzilla](https://bugzilla.mozilla.org/show_bug.cgi?id=1069405)

I have to tap out on this one. This is just too complex for me to diagnose: the commit is hundreds of very complicated lines, and it seems like it is a higher level issue: one that my library probably does not deal with. 

### CVE-2014-5165

> The `dissect_ber_constrained_bitstring` function in 
> `epan/dissectors/packet-ber.c` in the ASN.1 BER dissector in Wireshark 1.10.x 
> before 1.10.9 does not properly validate padding values, which allows remote 
> attackers to cause a denial of service (buffer underflow and application 
> crash) via a crafted packet.

```diff
while (nb->p_id) {
-   if ((len > 0) && (nb->bit < (8*len-pad))) {
+   if ((len > 0) && (pad < 8*len) && (nb->bit < (8*len-pad))) {
        val = tvb_get_guint8(tvb, offset + nb->bit/8);
        bitstring[(nb->bit/8)] &= ~(0x80 >> (nb->bit%8));
        val &= 0x80 >> (nb->bit%8);
```

If I understand 
[this bug](
        https://code.wireshark.org/review/gitweb?p=wireshark.git;a=commitdiff;h=17a552666b50896a9b9dde8ee6a1052e7f9a622e;hp=c30df319547442b3847693c821844735fd692d9c) 
correctly, the padding could be larger than the actual
number of bits in the `BIT STRING`. A maliciously-crafted packet would contain
a `BIT STRING` with a number of bits less than 255, and a padding value greater
than that, possibly even greater than 7, since the application does not stop
processing the encoded data upon encountering a padding value > 7; it looks
like it just leaves behind some sort of log message. Then, in this line:

```c
if ((len > 0) && (nb->bit < (8*len-pad))) {
```

the value `8*len-pad` underflows to `UINT_MAX`, which makes WireShark read off
anything that comes after the `BIT STRING` in memory as the encoded bytes of
the `BIT STRING`.

Although, the CVE description specifically mentions a "buffer underflow," which
I am not seeing. I see an integer underflow.

Either way, I need to add unit tests to `BIT STRING` to make sure it does not
crash or read out of bounds if padding > 7 && bits < 7.

### CVE-2014-3468

> The `asn1_get_bit_der` function in GNU Libtasn1 before 3.6 does not properly 
> report an error when a negative bit length is identified, which allows 
> context-dependent attackers to cause out-of-bounds access via crafted ASN.1 
> data.

With this bug, all I need to do is make sure that length is always an 
*unsigned* integral type (handy hint: it is), and make sure it cannot somehow underflow. (Update: I've tested with `size_t.max`.)

### CVE-2014-3467

> Multiple unspecified vulnerabilities in the DER decoder in GNU Libtasn1 
> before 3.6, as used in GnuTLS, allow remote attackers to cause a denial 
> of service (out-of-bounds read) via crafted ASN.1 data.

I could barely find any information on this one.

### CVE-2014-1316

> Heimdal, as used in Apple OS X through 10.9.2, allows remote attackers to 
> cause a denial of service (abort and daemon exit) via ASN.1 data 
> encountered in the Kerberos 5 protocol.

They are talking about [this Heimdal](http://www.h5l.org/). I cannot find any 
information about this vulnerability.

### CVE-2013-5018

> The `is_asn1` function in strongSwan 4.1.11 through 5.0.4 does not properly 
> validate the return value of the `asn1_length` function, which allows remote 
> attackers to cause a denial of service (segmentation fault) via a (1) XAuth 
> username, (2) EAP identity, or (3) PEM encoded file that starts with a 
> `0x04`, `0x30`, or `0x31` character followed by an ASN.1 length value that 
> triggers an integer overflow.

The segmentation fault is thrown on line 657 of `src/libstrongswan/asn1/asn1.c` 
of version 5.0.5 (and obviously, the analogous line in earlier versions):

```c
if (len + 1 == blob.len && *(blob.ptr + len) == '\n')
```

If the encoded ASN.1 value is of type `SET` or `SEQUENCE`, or in some versions,
`OCTET STRING`, it can make it to this line, which is why the CVE says it must 
start with `0x04`, `0x30` or `0x31` (the `OCTET STRING`, `SET` and `SEQUENCE` 
type tags, respectively). When it makes it to the line above, if the encoded 
data encodes a length of `0xFFFFFFFF`, and if the `blob` mentioned above is
empty, then the first condition may pass, because `UINT_MAX` overflows to `0`.

On the second condition, `blob.ptr + len` will sum to the address of the byte
in memory immediately before `blob` on 32-bit builds, and will just be about
4.2 gigabytes of memory higher (or lower, depending on how you look at it) in 
memory on 64-bit builds. If the resulting memory address lies in a page not
owned by the process, a segmentation fault occurs.

This means I need to make sure that length is not added to or subtracted from
in any part of the validation code, or make sure that the necessary checks are
in place if it does.

### CVE-2013-4935

> The `dissect_per_length_determinant` function in 
> `epan/dissectors/packet-per.c` in the ASN.1 PER dissector in Wireshark 1.8.x 
> before 1.8.9 and 1.10.x before 1.10.1 does not initialize a length field in 
> certain abnormal situations, which allows remote attackers to cause a denial 
> of service (application crash) via a crafted packet.

In line 638, which reads:

```c
buf = (guint8 *)g_malloc(length+1);
```

if length is set to `0xFFFFFFFF`, then `g_malloc` will allocate 0 bytes to the
buffer, then try to access the subsequent bytes in memory which it does not
own, resulting in a segmentation fault.

You should be fine searching for any time that a value is added to or 
subtracted from and ensuring that overflows cannot happen.

### CVE-2013-3557

> The `dissect_ber_choice` function in `epan/dissectors/packet-ber.c` in the 
> ASN.1 BER dissector in Wireshark 1.6.x before 1.6.15 and 1.8.x before 1.8.7 
> does not properly initialize a certain variable, which allows remote 
> attackers to cause a denial of service (application crash) via a malformed 
> packet.

There is almost no information on this one.

### CVE-2013-3556

> The `fragment_add_seq_common` function in `epan/reassemble.c` in the ASN.1 
> BER dissector in Wireshark before r48943 has an incorrect pointer dereference 
> during a comparison, which allows remote attackers to cause a denial of 
> service (application crash) via a malformed packet.

This bug is just caused by this little typo:

```diff
-                       if (*orig_keyp != NULL)
+                       if (orig_keyp != NULL)
```

### CVE-2012-0441

> The ASN.1 decoder in the QuickDER decoder in Mozilla Network Security 
> Services (NSS) before 3.13.4, as used in Firefox 4.x through 12.0, Firefox 
> ESR 10.x before 10.0.5, Thunderbird 5.0 through 12.0, Thunderbird ESR 10.x 
> before 10.0.5, and SeaMonkey before 2.10, allows remote attackers to cause a 
> denial of service (application crash) via a zero-length item, as demonstrated 
> by (1) a zero-length basic constraint or (2) a zero-length field in an OCSP 
> response.

From the [Bugzilla page](https://bugzilla.mozilla.org/show_bug.cgi?id=715073):

> From my reading of X.690, of the 25 ASN.1 UNIVERSAL types currently 
> recognized/defined in `secasn1t.h`, the following 7 can never have zero 
> length (when properly DER encoded): `BOOLEAN`, `INTEGER`, `BIT STRING`, 
> `OBJECT_IDENTIFIER`, `ENUMERATED`, `UTCTime`, `GeneralizedTime`. QuickDER 
> should abort further processing when the template specifies one of these 
> types and the buffer being processed holds such an illegal encoding.

- [x] Review how DER specifies that an `INTEGER` and `ENUMERATED` of zero 
        should be encoded.
~~Implement `invariant`s that ensure that all of the above types are never 
        zero-length.~~ Moved to `README.md`.

### CVE-2012-1569

> The `asn1_get_length_der` function in `decoding.c` in GNU Libtasn1 before 
> 2.12, as used in GnuTLS before 3.0.16 and other products, does not properly 
> handle certain large length values, which allows remote attackers to cause a 
> denial of service (heap memory corruption and application crash) or possibly 
> have unspecified other impact via a crafted ASN.1 structure.

Apparently, according to 
[this page](http://article.gmane.org/gmane.comp.gnu.libtasn1.general/54),
this was not actually a vulnerability, but rather, a lot of developers using
this library were not doing validation on the return value of 
`asn_get_length_der` that they were expected to do.

This bug is irrelevant to my code.

### CVE-2011-1142

> Stack consumption vulnerability in the `dissect_ber_choice` function in the 
> BER dissector in Wireshark 1.2.x through 1.2.15 and 1.4.x through 1.4.4 might 
> allow remote attackers to cause a denial of service (infinite loop) via 
> vectors involving self-referential ASN.1 CHOICE values.

I tried looking at the source code, and its just too damn complicated for me to 
figure out what causes the security vulnerability. I believe it has to do with 
this section (cleaned up slightly for readability):

```c
ch = choice;

if (branch_taken) {
    *branch_taken = -1;
}

first_pass = TRUE;
while (ch->func || first_pass) {
    if(branch_taken) {
        (*branch_taken)++;
    }
    /* we reset for a second pass when we will look for choices */
    if (!ch->func) {
    first_pass = FALSE;
    ch = choice; /* reset to the beginning */
    if(branch_taken) {
        *branch_taken = -1;
    }
}
```

Obviously, that section of code is not really that complicated, but learning 
all the data types and structures involved is. 

However, I can say that I believe that this bug is irrelevant to my code, 
because my code does not parse `CHOICE` types. It is on the developer to 
loop over the type tag of the "chosen" element and determine how to 
correctly decode it. It might behoove me, however, to leave a note for
developers using this library to be wary of this issue.

### CVE-2011-0445

> The ASN.1 BER dissector in Wireshark 1.4.0 through 1.4.2 allows remote 
> attackers to cause a denial of service (assertion failure) via crafted 
> packets, as demonstrated by `fuzz-2010-12-30-28473.pcap`.

This bug occurs on the same exact line that CVE-2014-5165 occurs on, in 
`epan/dissectors/packet-ber.c`.

```diff
-                       if(nb->bit < (8*len-pad)) {
+                       if(len > 0 && nb->bit < (8*len-pad)) {
```

Here they just didn't check that the length is actually greater than zero.

~~Review code for possible invalid zero lengths.~~ (Already noted.)

### CVE-2010-3445

> Stack consumption vulnerability in the `dissect_ber_unknown` function in 
> `epan/dissectors/packet-ber.c` in the BER dissector in Wireshark 1.4.x before 
> 1.4.1 and 1.2.x before 1.2.12 allows remote attackers to cause a denial of 
> service (`NULL` pointer dereference and crash) via a long string in an 
> unknown ASN.1/BER encoded packet, as demonstrated using SNMP.

[Here](https://xorl.wordpress.com/2010/10/15/cve-2010-3445-wireshark-asn-1-ber-stack-overflow/)
is a pretty good explanation of this vulnerability. Basically, there are no
recursion checks on nested BER-encoded elements, so you can send a message with 
a huge number of nested constructed elements, and with each constructed type 
tag encountered, it will recurse. Causing a stack overflow, then, is a simple 
matter of sending a repeating sequence of constructed type tags, each of 
which is followed by a length tag, of course.

Again, this is irrelevant to my code. My code decodes only a single "layer"
of recursion at a time. It is possible for a developer using this library
to make this mistake, however, so it is important that I leave a heads up
for developers.

### CVE-2010-2994

> Stack-based buffer overflow in the ASN.1 BER dissector in Wireshark 0.10.13 
> through 1.0.14 and 1.2.0 through 1.2.9 has unknown impact and remote attack 
> vectors. NOTE: this issue exists because of a CVE-2010-2284 regression.

Jeez, is WireShark the only product that has ever had any vulnerabilities?

As stated above "this issue exists because of a CVE-2010-2284 regression." 
Moving on.

### CVE-2010-2284

> Buffer overflow in the ASN.1 BER dissector in Wireshark 0.10.13 through 
> 1.0.13 and 1.2.0 through 1.2.8 has unknown impact and remote attack vectors.

I cannot find a bug or commit confirmed to be associated with this CVE, but I 
found 
[this commmit](
        https://code.wireshark.org/review/gitweb?p=wireshark.git;a=commitdiff;h=edb7f000dc5b342c311977c327be1bac0767ff06)
that appears to fix possible infinite recursion.

Again, with the other infinite recursion / stack overflow bugs mentioned above,
this one does not really relate to my code, because my code does not recurse.

~~However, it is possible to encode indefinite-length encoded elements in other 
indefinite-length elements, which would *require* recursion to determine the
length, so I definitely need to review my code for this possibility.~~

~~Make sure IL elements can contain other IL elements.~~
_NOTE: This looks like this is going to be a problem, because my code does not parse indefinite-length items totally correctly... Or is it? X.690 just says that IL ends with the double null; nothing else._

### CVE-2009-3877

> Unspecified vulnerability in Sun Java SE in JDK and JRE 5.0 before Update 22, 
> JDK and JRE 6 before Update 17, SDK and JRE 1.3.x before 1.3.1\_27, and SDK 
> and JRE 1.4.x before 1.4.2\_24 allows remote attackers to cause a denial of 
> service (memory consumption) via crafted HTTP headers, which are not properly 
> parsed by the ASN.1 DER input stream parser, aka Bug Id 6864911.

[This bug](http://bugs.java.com/bugdatabase/view_bug.do?bug_id=6864911) is no 
longer available.

Skipping, because I think this is closed source anyway.

### CVE-2009-3876

Ditto.

### CVE-2009-2511

Closed source. Unable to research.

### CVE-2009-2661

> The `asn1_length` function in strongSwan 2.8 before 2.8.11, 4.2 before 
> 4.2.17, and 4.3 before 4.3.3 does not properly handle X.509 certificates 
> with crafted Relative Distinguished Names (RDNs), which allows remote 
> attackers to cause a denial of service (pluto IKE daemon crash) via 
> malformed ASN.1 data. NOTE: this is due to an incomplete fix for 
> CVE-2009-2185.

Noted "this is due to an incomplete fix for CVE-2009-2185." Moving on.

### CVE-2009-2185

> The ASN.1 parser (`pluto/asn1.c`, `libstrongswan/asn1/asn1.c`, 
> `libstrongswan/asn1/asn1_parser.c`) in (a) strongSwan 2.8 before 2.8.10, 4.2 
> before 4.2.16, and 4.3 before 4.3.2; and (b) openSwan 2.6 before 2.6.22 and 
> 2.4 before 2.4.15 allows remote attackers to cause a denial of service (pluto 
> IKE daemon crash) via an X.509 certificate with (1) crafted Relative 
> Distinguished Names (RDNs), (2) a crafted `UTCTIME` string, or (3) a crafted 
> `GENERALIZEDTIME` string.

There is a lot that went into this vulnerability. Basically, the developers 
just failed to do the most basic length checks.

### CVE-2009-0847

> The `asn1buf_imbed` function in the ASN.1 decoder in MIT Kerberos 5 (aka 
> krb5) 1.6.3, when PK-INIT is used, allows remote attackers to cause a denial 
> of service (application crash) via a crafted length value that triggers an 
> erroneous `malloc` call, related to incorrect calculations with pointer 
> arithmetic.

It looks like version 1.6.3 was removed altogether, so I cannot research this
one; but, I suspect this is just like CVE-2013-4935.

### CVE-2009-0846

> The `asn1_decode_generaltime` function in `lib/krb5/asn.1/asn1_decode.c` in 
> the ASN.1 `GeneralizedTime` decoder in MIT Kerberos 5 (aka krb5) before 1.6.4 
> allows remote attackers to cause a denial of service (daemon crash) or 
> possibly execute arbitrary code via vectors involving an invalid DER encoding 
> that triggers a free of an uninitialized pointer.

This bug was only caused by nothing being done with the return value of
`asn1buf_remove_charstring`. So when the program encountered a problem
decoding the ASN.1 element, the code would continue even though the
output buffer, `s`, was never actually initialized. The second line
below was added in version 1.6.4, which fixed this bug.

```c
retval = asn1buf_remove_charstring(buf,15,&s);
if (retval) return retval;
```

I don't think there is actually a lesson to learn here at all. This was just 
dumb. The end.

### CVE-2009-0789

> OpenSSL before 0.9.8k on WIN64 and certain other platforms does not properly 
> handle a malformed ASN.1 structure, which allows remote attackers to cause a 
> denial of service (invalid memory access and application crash) by placing 
> this structure in the public key of a certificate, as demonstrated by an RSA 
> public key.

From [this advisory](https://www.openssl.org/news/secadv/20090325.txt):

> When a malformed ASN1 structure is received it's contents are freed up and 
> zeroed and an error condition returned. On a small number of platforms where 
> `sizeof(long) < sizeof(void *)` (for example WIN64) this can cause an invalid 
> memory access later resulting in a crash when some invalid structures are 
> read, for example RSA public keys (CVE-2009-0789).

Short term fix: `static assert` blocking code from compiling when 
`long.sizeof < (void *).sizeof`.

Long term fix: actually fix the code.

Although, I really don't think this bug should affect my code at all. I don't 
I cast between pointers and `long`s in my code.

### CVE-2008-2952

> `liblber/io.c` in OpenLDAP 2.2.4 to 2.4.10 allows remote attackers to cause a 
> denial of service (program termination) via crafted ASN.1 BER datagrams that 
> trigger an assertion error.

This shit is exactly what Uncle Bob was griping about:

```diff
 			/* Not enough bytes? */
-			if (ber->ber_rwptr - (char *)p < llen) {
-#if defined( EWOULDBLOCK )
-				sock_errset(EWOULDBLOCK);
-#elif defined( EAGAIN )
-				sock_errset(EAGAIN);
-#endif			
-				return LBER_DEFAULT;
+			i = ber->ber_rwptr - (char *)p;
+			if (i < llen) {
+				sblen=ber_int_sb_read( sb, ber->ber_rwptr, i );
+				if (sblen<i) return LBER_DEFAULT;
+				ber->ber_rwptr += sblen;
 			}
 			for (i=0; i<llen; i++) {
 				tlen <<=8;
```

I'm not reviewing this. Sorry.

### CVE-2008-1673

> The asn1 implementation in (a) the Linux kernel 2.4 before 2.4.36.6 and 2.6 
> before 2.6.25.5, as used in the `cifs` and `ip_nat_snmp_basic` modules; and 
> (b) the `gxsnmp` package; does not properly validate length values during 
> decoding of ASN.1 BER data, which allows remote attackers to cause a denial 
> of service (crash) or execute arbitrary code via (1) a length greater than 
> the working buffer, which can lead to an unspecified overflow; (2) an oid 
> length of zero, which can lead to an off-by-one error; or (3) an indefinite 
> length for a primitive encoding.

This appears to be the result of a few checks that were not done.

```diff
+	/* don't trust len bigger than ctx buffer */
+	if (*len > ctx->end - ctx->pointer)
+		return 0;
```

This makes sure that the reported length is not longer than the length of all
encoded data.

```diff
+	/* primitive shall be definite, indefinite shall be constructed */
+	if (*con == ASN1_PRI && !def)
+		return 0;
```

The comment says all.

```diff
    size = eoc - ctx->pointer + 1;

+	/* first subid actually encodes first two subids */
+	if (size < 2 || size > ULONG_MAX/sizeof(unsigned long))
+		return 0;
```

If the element is less than two bytes in length, it cannot be a valid ASN.1
element. I don't know why is must be no larger than 
`ULONG/sizeof(unsigned long)`.

The other checks added to the diff for that commit are duplicates of the
checks above.

- [x] Check that length tag indicates length less than data length.
~~[ ] Set PC to constructed if indefinite encoding is used. (Check that this 
        is actually a rule, too.)~~ (Scheduled for 2.0.0.)
- [x] Check that encoded value is at least two bytes long (one for type, one for length).

### CVE-2006-3894

> The RSA Crypto-C before 6.3.1 and Cert-C before 2.8 libraries, as used by RSA 
> BSAFE, multiple Cisco products, and other products, allows remote attackers 
> to cause a denial of service via malformed ASN.1 objects.

Closed source. Skipping.

### CVE-2006-6836

> Multiple unspecified vulnerabilities in osp-cert in IBM OS/400 V5R3M0 have 
> unspecified impact and attack vectors, related to ASN.1 parsing.

Closed source. Skipping.

### CVE-2006-2937

> OpenSSL 0.9.7 before 0.9.7l and 0.9.8 before 0.9.8d allows remote attackers 
> to cause a denial of service (infinite loop and memory consumption) via 
> malformed ASN.1 structures that trigger an improperly handled error 
> condition.

I really cannot figure out what causes the infinite loop here. I've looked at 
the patch, and, though there are a few changes to control flow (replacement of
`goto err` with `return -1`, for instance), I can't see anything that would 
cause an infinite loop in the first place. I might have to get an expert on
OpenSSL to weigh in here.

The patch is 
[here](http://security.FreeBSD.org/patches/SA-06:23/openssl.patch),
but also saved in `documentation/miscellaneous/CVE-2006-2937.patch`, just in 
case that link breaks.

### CVE-2006-1939

> Multiple unspecified vulnerabilities in Ethereal 0.9.x up to 0.10.14 allow 
> remote attackers to cause a denial of service (crash from null dereference) 
> via (1) an invalid display filter, or the (2) GSM SMS, (3) ASN.1-based, (4) 
> DCERPC NT, (5) PER, (6) RPC, (7) DCERPC, and (8) ASN.1 dissectors.

Welp, "unspecified vulnerabilities" is my excuse for not looking into this.

### CVE-2006-0645

> Tiny ASN.1 Library (libtasn1) before 0.2.18, as used by (1) GnuTLS 1.2.x 
> before 1.2.10 and 1.3.x before 1.3.4, and (2) GNU Shishi, allows attackers 
> to crash the DER decoder and possibly execute arbitrary code via 
> "out-of-bounds access" caused by invalid input, as demonstrated by the 
> ProtoVer SSL test suite.

The patch for this one is huge, and I don't see which part of it deals with 
the invalid input. I got the patch from 
[here](https://bugzilla.redhat.com/attachment.cgi?id=124516), but I also saved
it in `documentation/miscellaneous/CVE-2006-0645.patch` in case that link 
breaks.

### CVE-2005-1730

> Multiple vulnerabilities in the OpenSSL ASN.1 parser, as used in Novell 
> iManager 2.0.2, allows remote attackers to cause a denial of service (`NULL` 
> pointer dereference) via crafted packets, as demonstrated by "OpenSSL ASN.1 
> brute forcer." NOTE: this issue might overlap CVE-2004-0079, CVE-2004-0081, 
> or CVE-2004-0112.

I managed to download the [exploit malware source](
        http://downloads.securityfocus.com/vulnerabilities/exploits/ASN.1-Brute.c), 
which is saved in `documentation/miscellaneous/exploit-CVE-2005-1730.c`.
The author says you can use it [here](
        http://www.derkeiler.com/Mailing-Lists/securityfocus/bugtraq/2004-01/0126.html).

~~I will have to analyze it to discover the exploit (and possibly run it on my
system).~~

It looks like the malware I downloaded just (pseudo-)randomly corrupts the packet.
There is no actual indication as to what in particular causes the vulnerability.
I have to skip this one.

### CVE-2005-1935

> Heap-based buffer overflow in the `BERDecBitString` function in Microsoft 
> ASN.1 library (`MSASN1.DLL`) allows remote attackers to execute arbitrary 
> code via nested constructed bit strings, which leads to a realloc of a 
> non-null pointer and causes the function to overwrite previously freed 
> memory, as demonstrated using a SPNEGO token with a constructed bit string 
> during HTTP authentication, and a different vulnerability than CVE-2003-0818. 
> NOTE: the researcher has claimed that MS:MS04-007 fixes this issue.

Closed source. Skipping.

### CVE-2004-2344

> Unknown vulnerability in the ASN.1/H.323/H.225 stack of VocalTec VGW120 and 
> VGW480 allows remote attackers to cause a denial of service.

Closed source, ancient, and "Unknown vulnerability." Skipping.

### CVE-2004-2644

> Unspecified vulnerability in ASN.1 Compiler (`asn1c`) before 0.9.7 has 
> unknown impact and attack vectors when processing "ANY" type tags.

This library does not compile ASN.1, so this is irrelevant, but I will keep it
in mind if that ever changes.

### CVE-2004-2645

> Unspecified vulnerability in ASN.1 Compiler (`asn1c`) before 0.9.7 has 
> unknown impact and attack vectors when processing "CHOICE" types with 
> "indefinite length structures."

Ditto.

### CVE-2004-0642

> Double free vulnerabilities in the error handling code for ASN.1 decoders in 
> the (1) Key Distribution Center (KDC) library and (2) client library for MIT 
> Kerberos 5 (krb5) 1.3.4 and earlier may allow remote attackers to execute 
> arbitrary code.

Pretty simple: they failed to check if something was already freed before 
trying to free it again. This does not apply to my code, since I do not do any
manual memory management in D.

### CVE-2004-0644

> The `asn1buf_skiptail` function in the ASN.1 decoder library for MIT Kerberos 
> 5 (`krb5`) 1.2.2 through 1.3.4 allows remote attackers to cause a denial of 
> service (infinite loop) via a certain BER encoding.

I can't even find this version of the source code. I gave it an honest effort.

### CVE-2004-0699

> Heap-based buffer overflow in ASN.1 decoding library in Check Point VPN-1 
> products, when Aggressive Mode IKE is implemented, allows remote attackers 
> to execute arbitrary code by initiating an IKE negotiation and then sending 
> an IKE packet with malformed ASN.1 data.

Closed source. Skipping.

### CVE-2004-0123

> Double free vulnerability in the ASN.1 library as used in Windows NT 4.0, 
> Windows 2000, Windows XP, and Windows Server 2003, allows remote attackers 
> to cause a denial of service and possibly execute arbitrary code.

Closed source. Skipping.

### CVE-2003-0818

> Multiple integer overflows in Microsoft ASN.1 library (`MSASN1.DLL`), as used 
> in `LSASS.EXE`, `CRYPT32.DLL`, and other Microsoft executables and libraries 
> on Windows NT 4.0, 2000, and XP, allow remote attackers to execute arbitrary 
> code via ASN.1 BER encodings with (1) very large length fields that cause 
> arbitrary heap data to be overwritten, or (2) modified bit strings.

Closed source. Skipping.

### CVE-2005-1247

> `webadmin.exe` in Novell Nsure Audit 1.0.1 allows remote attackers to cause a 
> denial of service via malformed ASN.1 packets in corrupt client certificates 
> to an SSL server, as demonstrated using an exploit for the OpenSSL ASN.1 
> parsing vulnerability.

Closed source. Skipping.

### CVE-2003-1005

> The PKI functionality in Mac OS X 10.2.8 and 10.3.2 allows remote attackers 
> to cause a denial of service (service crash) via malformed ASN.1 sequences.

Closed source. Skipping.

### CVE-2003-0564

> Multiple vulnerabilities in multiple vendor implementations of the 
> Secure/Multipurpose Internet Mail Extensions (S/MIME) protocol allow remote 
> attackers to cause a denial of service and possibly execute arbitrary code 
> via an S/MIME email message containing certain unexpected ASN.1 constructs, 
> as demonstrated using the NISSC test suite.

This appears to apply only to proprietary software. Skipping.

### CVE-2003-0565

> Multiple vulnerabilities in multiple vendor implementations of the X.400 
> protocol allow remote attackers to cause a denial of service and possibly 
> execute arbitrary code via an X.400 message containing certain unexpected 
> ASN.1 constructs, as demonstrated using the NISSC test suite.

Several links broken. Unclear problem. Skipping.

### CVE-2003-0851

> OpenSSL 0.9.6k allows remote attackers to cause a denial of service (crash 
> via large recursion) via malformed ASN.1 sequences.

I can hardly understand the changes made in this 
[commit](https://git.openssl.org/?p=openssl.git;a=commitdiff;h=83f70d68d6c3086241c041ba26786fd822179f2e).

Geriatric code strikes once more:

```diff
--- a/crypto/asn1/a_bytes.c
+++ b/crypto/asn1/a_bytes.c
@@ -201,7 +201,10 @@ ASN1_STRING *d2i_ASN1_bytes(ASN1_STRING **a, unsigned char **pp, long length,
                c.pp=pp;
                c.p=p;
                c.inf=inf;
-               c.slen=len;
+               if (inf & 1)
+                       c.slen = length - (p - *pp);
+               else
+                       c.slen=len;
                c.tag=Ptag;
                c.xclass=Pclass;
                c.max=(length == 0)?0:(p+length);
@@ -279,8 +282,7 @@ static int asn1_collate_primitive(ASN1_STRING *a, ASN1_CTX *c)
                {
                if (c->inf & 1)
                        {
-                       c->eos=ASN1_check_infinite_end(&c->p,
-                               (long)(c->max-c->p));
+                       c->eos=ASN1_check_infinite_end(&c->p, c->slen);
                        if (c->eos) break;
                        }
                else
@@ -289,7 +291,7 @@ static int asn1_collate_primitive(ASN1_STRING *a, ASN1_CTX *c)
                        }
 
                c->q=c->p;
-               if (d2i_ASN1_bytes(&os,&c->p,c->max-c->p,c->tag,c->xclass)
+               if (d2i_ASN1_bytes(&os,&c->p,c->slen,c->tag,c->xclass)
                        == NULL)
                        {
                        c->error=ERR_R_ASN1_LIB;
@@ -302,8 +304,7 @@ static int asn1_collate_primitive(ASN1_STRING *a, ASN1_CTX *c)
                        goto err;
                        }
                memcpy(&(b.data[num]),os->data,os->length);
-               if (!(c->inf & 1))
-                       c->slen-=(c->p-c->q);
+               c->slen-=(c->p-c->q);
                num+=os->length;
                }
```

Fortunately for me, my library does no recursion (I think; it's getting so big
that I can't remember), so I think this is irrelevant to my code.

### CVE-2003-0543

> Integer overflow in OpenSSL 0.9.6 and 0.9.7 allows remote attackers to cause 
> a denial of service (crash) via an SSL client certificate with certain ASN.1 
> tag values.

Fixed in 
[this commit](
        https://git.openssl.org/?p=openssl.git;a=commitdiff;h=3c28bfdc822517fac18c2ce8a2542ae12ff645dc),
specifically in this change:

```diff
                        l<<=7L;
                        l|= *(p++)&0x7f;
                        if (--max == 0) goto err;
+                       if (l > (INT_MAX >> 7L)) goto err;
                        }
                l<<=7L;
                l|= *(p++)&0x7f;
                tag=(int)l;
+               if (--max == 0) goto err;
```

- [x] Ascertain that 0xFF cannot be used as a length tag.
- [x] Review section 8.1.2.4 of X.690. You omitted some functionality. It turns out that you can have infinitely many tags.

### CVE-2003-0544

> OpenSSL 0.9.6 and 0.9.7 does not properly track the number of characters in 
> certain ASN.1 inputs, which allows remote attackers to cause a denial of 
> service (crash) via an SSL client certificate that causes OpenSSL to read 
> past the end of a buffer when the long form is used.

Ditto.

### CVE-2003-0545

> Double free vulnerability in OpenSSL 0.9.7 allows remote attackers to cause a 
> denial of service (crash) and possibly execute arbitrary code via an SSL 
> client certificate with a certain invalid ASN.1 encoding.

On this [commit](
        https://git.openssl.org/?p=openssl.git;a=commitdiff;h=662ede2370e0fa1f571354fbba9ac7ee9caf6706),
the following diff fixed this vulnerability:

```diff
--- a/crypto/asn1/tasn_dec.c
+++ b/crypto/asn1/tasn_dec.c
@@ -691,6 +691,7 @@ static int asn1_d2i_ex_primitive(ASN1_VALUE **pval, unsigned char **in, long inl
 
 int asn1_ex_c2i(ASN1_VALUE **pval, unsigned char *cont, int len, int utype, char *free_cont, const ASN1_ITEM *it)
 {
+       ASN1_VALUE **opval = NULL;
        ASN1_STRING *stmp;
        ASN1_TYPE *typ = NULL;
        int ret = 0;
@@ -705,6 +706,7 @@ int asn1_ex_c2i(ASN1_VALUE **pval, unsigned char *cont, int len, int utype, char
                        *pval = (ASN1_VALUE *)typ;
                } else typ = (ASN1_TYPE *)*pval;
                if(utype != typ->type) ASN1_TYPE_set(typ, utype, NULL);
+               opval = pval;
                pval = (ASN1_VALUE **)&typ->value.ptr;
        }
        switch(utype) {
@@ -796,7 +798,12 @@ int asn1_ex_c2i(ASN1_VALUE **pval, unsigned char *cont, int len, int utype, char
 
        ret = 1;
        err:
-       if(!ret) ASN1_TYPE_free(typ);
+       if(!ret)
+               {
+               ASN1_TYPE_free(typ);
+               if (opval)
+                       *opval = NULL;
+               }
        return ret;
 }
```

Again, I don't manage memory manually, so I don't have to worry about this.

### CVE-2003-0430

> The SPNEGO dissector in Ethereal 0.9.12 and earlier allows remote attackers 
> to cause a denial of service (crash) via an invalid ASN.1 value.

From this 
[commit](https://code.wireshark.org/review/gitweb?p=wireshark.git;a=commitdiff;h=47817bcb26d93f40da5235d72510f17e5c2dac98),
I believe this diff is the fix for this vulnerability, but I am uncertain:

```diff
--- a/packet-spnego.c
+++ b/packet-spnego.c
@@ -5,7 +5,7 @@
  * Copyright 2002, Richard Sharpe <rsharpe@ns.aus.com>
  * Copyright 2003, Richard Sharpe <rsharpe@richardsharpe.com>
  *
- * $Id: packet-spnego.c,v 1.49 2003/05/26 20:44:20 guy Exp $
+ * $Id: packet-spnego.c,v 1.50 2003/06/01 20:34:20 sharpe Exp $
  *
  * Ethereal - Network traffic analyzer
  * By Gerald Combs <gerald@ethereal.com>
@@ -1106,19 +1106,26 @@ dissect_spnego_responseToken(tvbuff_t *tvb, int offset, packet_info *pinfo _U_,
 
        offset = hnd->offset;
 
-       item = proto_tree_add_item(tree, hf_spnego_responsetoken, tvb, offset, 
-                                  nbytes, FALSE); 
+       item = proto_tree_add_item(tree, hf_spnego_responsetoken, tvb, offset -2 , 
+                                  nbytes + 2, FALSE); 
 
        subtree = proto_item_add_subtree(item, ett_spnego_responsetoken);
 
+
        /*
         * Now, we should be able to dispatch after creating a new TVB.
+        * However, we should make sure that there is something in the 
+        * response token ...
         */
 
-       token_tvb = tvb_new_subset(tvb, offset, nbytes, -1);
-       if (next_level_dissector)
-         call_dissector(next_level_dissector, token_tvb, pinfo, subtree);
-
+       if (nbytes) {
+         token_tvb = tvb_new_subset(tvb, offset, nbytes, -1);
+         if (next_level_dissector)
+           call_dissector(next_level_dissector, token_tvb, pinfo, subtree);
+       }
+       else {
+         proto_tree_add_text(subtree, tvb, offset-2, 2, "<Empty String>");
+       }
        hnd->offset += nbytes; /* Update this ... */
 
  done:
@@ -1660,4 +1667,9 @@ proto_reg_handoff_spnego(void)
        gssapi_init_oid("1.2.840.113554.1.2.2", proto_spnego_krb5, ett_spnego_krb5,
                        spnego_krb5_handle, spnego_krb5_wrap_handle,
                        "KRB5 - Kerberos 5");
+
+       /*
+        * Find the data handle for some calls
+        */
+       data_handle = find_dissector("data");
 }
```

This is just a matter of checking that a string is not empty before trying to 
access a non-existent first character. This is obviously relevant to my code,
but not in any profound way that I have failed to keep wary of.

### CVE-2002-0036

> Integer signedness error in MIT Kerberos V5 ASN.1 decoder before krb5 1.2.5 
> allows remote attackers to cause a denial of service via a large unsigned 
> data element length, which is later used as a negative value.

It's going to be a freaking nightmare for me to track down this diff, and then
figure out what exactly the offending code looks like, but fortunately, I think
the description for this CVE is descriptive enough for me to be able to skip 
that. This sounds like similar bugs that I have come across earlier in this CVE
review.

### CVE-2002-0353

> The ASN.1 parser in Ethereal 0.9.2 and earlier allows remote attackers to 
> cause a denial of service (crash) via a certain malformed packet, which 
> causes Ethereal to allocate memory incorrectly, possibly due to 
> zero-length fields.

I believe this is the 
[commit](https://code.wireshark.org/review/gitweb?p=wireshark.git;a=commitdiff;h=b6e941027ff5b41a55bf23ce43d23e8ea5d49efc)
that fixed this vulnerability, but I cannot confirm. The security advisories do
not really sound too sure of what the cause of the vulnerability is.