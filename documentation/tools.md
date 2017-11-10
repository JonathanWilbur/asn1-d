# How to Use the Command Line Tools

Cool trick:
Decode PEM-encoded X.509 certificates using the following command:
`tail -n +2 <path to cert> | head -n -1 | base64 --decode`

## Decode

Basically,

`decode-<codec> -f <file name>`

That's it.