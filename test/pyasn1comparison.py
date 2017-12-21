#!/usr/bin/python
from hexdump import hexdump, dump
from pyasn1.codec.ber.encoder import encode as ber_encode
from pyasn1.codec.cer.encoder import encode as cer_encode
from pyasn1.codec.der.encoder import encode as der_encode
from pyasn1.type import univ, char

# BER

print("*** BASIC ENCODING RULES ***")

print("BOOLEAN True")
bytes = ber_encode(univ.Boolean(True))
print(dump(bytes))

print("BOOLEAN False")
bytes = ber_encode(univ.Boolean(False))
print(dump(bytes))

print("INTEGER 5")
bytes = ber_encode(univ.Integer(5))
print(dump(bytes))

print("INTEGER 90000")
bytes = ber_encode(univ.Integer(90000))
print(dump(bytes))

print("BITSTRING 101100111000")
bytes = ber_encode(univ.BitString("101100111000"))
print(dump(bytes))

print("BITSTRING 10110100")
bytes = ber_encode(univ.BitString("10110100"))
print(dump(bytes))

print("OCTET STRING 'HENLO BORTHERS'")
bytes = ber_encode(univ.OctetString("HENLO BORTHERS"))
print(dump(bytes))

print("NULL")
bytes = ber_encode(univ.Null())
print(dump(bytes))

print("OBJECT IDENTIFIER 1.2.0.256.79999.7")
bytes = ber_encode(univ.ObjectIdentifier((1,2,0,256,79999,7)))
print(dump(bytes))

print("REAL 1.23")
bytes = ber_encode(univ.Real(1.23))
print(dump(bytes))

print("REAL -0.33")
bytes = ber_encode(univ.Real(-0.33))
print(dump(bytes))

print("REAL { 45 2 31 }")
bytes = ber_encode(univ.Real((45, 2, 31)))
print(dump(bytes))

print("ENUMERATED 5")
bytes = ber_encode(univ.Enumerated(5))
print(dump(bytes))

print("ENUMERATED 90000")
bytes = ber_encode(univ.Enumerated(90000))
print(dump(bytes))

print("BMPString 'HENLO BORTHERS'");
bytes = ber_encode(char.BMPString("HENLO BORTHERS"))
print(dump(bytes))

print("UniversalString 'HENLO BORTHERS'");
bytes = ber_encode(char.UniversalString("HENLO BORTHERS"))
print(dump(bytes))

print("\n")

# CER

print("*** CANONICAL ENCODING RULES ***")

print("BOOLEAN True")
bytes = cer_encode(univ.Boolean(True))
print(dump(bytes))

print("BOOLEAN False")
bytes = cer_encode(univ.Boolean(False))
print(dump(bytes))

print("INTEGER 5")
bytes = cer_encode(univ.Integer(5))
print(dump(bytes))

print("INTEGER 90000")
bytes = cer_encode(univ.Integer(90000))
print(dump(bytes))

print("BITSTRING 101100111000")
bytes = cer_encode(univ.BitString("101100111000"))
print(dump(bytes))

print("BITSTRING 10110100")
bytes = cer_encode(univ.BitString("10110100"))
print(dump(bytes))

print("OCTET STRING 'HENLO BORTHERS'")
bytes = cer_encode(univ.OctetString("HENLO BORTHERS"))
print(dump(bytes))

print("NULL")
bytes = cer_encode(univ.Null())
print(dump(bytes))

print("OBJECT IDENTIFIER 1.2.0.256.79999.7")
bytes = cer_encode(univ.ObjectIdentifier((1,2,0,256,79999,7)))
print(dump(bytes))

print("REAL 1.23")
bytes = cer_encode(univ.Real(1.23))
print(dump(bytes))

print("REAL -0.33")
bytes = cer_encode(univ.Real(-0.33))
print(dump(bytes))

print("REAL { 45 2 31 }")
bytes = cer_encode(univ.Real((45, 2, 31)))
print(dump(bytes))

print("ENUMERATED 5")
bytes = cer_encode(univ.Enumerated(5))
print(dump(bytes))

print("ENUMERATED 90000")
bytes = cer_encode(univ.Enumerated(90000))
print(dump(bytes))

print("BMPString 'HENLO BORTHERS'");
bytes = cer_encode(char.BMPString("HENLO BORTHERS"))
print(dump(bytes))

print("\n")

# DER

print("*** DISTINGUISHED ENCODING RULES ***")

print("BOOLEAN True")
bytes = der_encode(univ.Boolean(True))
print(dump(bytes))

print("BOOLEAN False")
bytes = der_encode(univ.Boolean(False))
print(dump(bytes))

print("INTEGER 5")
bytes = der_encode(univ.Integer(5))
print(dump(bytes))

print("INTEGER 90000")
bytes = der_encode(univ.Integer(90000))
print(dump(bytes))

print("BITSTRING 101100111000")
bytes = der_encode(univ.BitString("101100111000"))
print(dump(bytes))

print("BITSTRING 10110100")
bytes = der_encode(univ.BitString("10110100"))
print(dump(bytes))

print("OCTET STRING 'HENLO BORTHERS'")
bytes = der_encode(univ.OctetString("HENLO BORTHERS"))
print(dump(bytes))

print("NULL")
bytes = der_encode(univ.Null())
print(dump(bytes))

print("OBJECT IDENTIFIER 1.2.0.256.79999.7")
bytes = der_encode(univ.ObjectIdentifier((1,2,0,256,79999,7)))
print(dump(bytes))

print("REAL 1.23")
bytes = der_encode(univ.Real(1.23))
print(dump(bytes))

print("REAL -0.33")
bytes = der_encode(univ.Real(-0.33))
print(dump(bytes))

print("REAL { 45 2 31 }")
bytes = der_encode(univ.Real((45, 2, 31)))
print(dump(bytes))

print("ENUMERATED 5")
bytes = der_encode(univ.Enumerated(5))
print(dump(bytes))

print("ENUMERATED 90000")
bytes = der_encode(univ.Enumerated(90000))
print(dump(bytes))

print("BMPString 'HENLO BORTHERS'");
bytes = der_encode(char.BMPString("HENLO BORTHERS"))
print(dump(bytes))

print("UniversalString 'HENLO BORTHERS'");
bytes = der_encode(char.UniversalString("HENLO BORTHERS"))
print(dump(bytes))

print("\n")