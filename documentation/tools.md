# How to Use the Command Line Tools

## Decode

Decoding is really straight-forward. Either pipe in the raw binary, or, if no
piped input is provided, the program will seem to "freeze," but it is really
just waiting on input from you. If the data you wish to encode can be
represented entirely with characters found on your keyboard, you can enter
them, then press Ctrl+D once or twice to exit the keyboard input.

This will parse the piped input:

```bash
cat x509certificate.der | ./build/executables/decode-der
```

This will accept keyboard input until Ctrl-D is pressed to end the keyboard
input, or until Ctrl-C is pressed to terminate the program:

```bash
./build/executables/decode-der
```

## Encode

Encoding is a bit more complicated, but conceptually simple: you provide
arguments, where each argument describes a single ASN.1 element to encode.

The structure of each argument is like this:

`"[" + [U|A|C|P] + [P|C] + A number + "]::=" + Encoding method + ":" + value literal + "]"`

The syntax of each argument is intended to be like ASN.1 itself, in case you
were wondering.

The first option for an element is the tag class, which can be indicated with
a `U` for `UNIVERSAL`, `A` for `APPLICATION`, `C` for `CONTEXT-SPECIFIC`, or
`P` for `PRIVATELY-DEFINED`. The second option is the construction, which is
indicated with either a `P` for `PRIMITIVE` or `C` for `CONSTRUCTED`. The
third option is the tag number.

As an example, `[UP6]` encodes a `UNIVERSAL PRIMITIIVE 6`, which is an
`OBJECT IDENTIFIER`.

The second part of each element indicates the value to be encoded. This part
must contain a colon, and the part of it that occurs before the colon indicates
what method should be used to encode the data that comes after the colon. For
instance, `bool:TRUE` encodes a true boolean. If you were to use a different
method, the `TRUE` value might be interpreted differently. For instance,
`utf8:TRUE` would encode the UTF-8 string "TRUE". Likewise, `int:5` would
encode the `INTEGER` 5, but `numeric:5` would encode the `NumericString` of
"5", which would be encoded as the UTF-8 character for '5'.

The available methods for encoding are:

Method      | Encodes as        | Argument
------------|-------------------|---------------
eoc         | END OF CONTENT    | N/A
bool        | BOOLEAN           | TRUE or FALSE
int         | INTEGER           | Any integer
bit         | BIT STRING        | A sequence of 1s and 0s
oct         | OCTET STRING      | Hexadecimal
null        | NULL              | N/A
oid         | OBJECT IDENTIFIER | An object identifier, such as "1.3.4.6.1"
od          | ObjectDescriptor  | A string
real        | REAL              | A floating point number, such as -22.86
enum        | ENUMERATED        | Any integer
utf8        | UTF8String        | A string
roid        | RELATIVE OID      | A part of an object identifier, such as "4.6.1"
numeric     | NumericString     | A string of only numbers or space
printable   | PrintableString   | A string
teletex     | TeletexString     | Hexadecimal
videotex    | VideotexString    | Hexadecimal
ia5         | IA5String         | A string
utc         | UTCTime           | A DateTime String of the form YYYYMMDDTHHMMSS
time        | GeneralizedTime   | A DateTime String of the form YYYYMMDDTHHMMSS
graphic     | GraphicString     | A string
visible     | VisibleString     | A string
general     | GeneralString     | A string
universal   | UniversalString   | A string
bmp         | BMPString         | A string

## Complete Example

Encode like so:

```bash
./build/executables/encode-der \
[UP1]::=bool:TRUE \
[UP2]::=int:5 \
[UP3]::=bit:110110 \
[UP4]::=oct:0AFEBCD159 \
[UP22]::=ia5:testeroni > test.der
```

Now the raw binary data is stored in `test.der`. Decode it like so:

```bash
cat test.der | ./build/executables/decode-der
```

## Cool Trick

You can decode a PEM-encoded X.509 certificates using the following command:
`tail -n +2 <path to cert> | head -n -1 | base64 --decode | decode-der`