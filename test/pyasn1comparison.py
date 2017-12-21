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

# Output:

# *** BASIC ENCODING RULES ***
# BOOLEAN True
# 01 01 01
# BOOLEAN False
# 01 01 00
# INTEGER 5
# 02 01 05
# INTEGER 90000
# 02 03 01 5F 90
# BITSTRING 101100111000
# 03 03 04 B3 80
# BITSTRING 10110100
# 03 02 00 B4
# OCTET STRING 'HENLO BORTHERS'
# 04 0E 48 45 4E 4C 4F 20 42 4F 52 54 48 45 52 53
# NULL
# 05 00
# OBJECT IDENTIFIER 1.2.0.256.79999.7
# 06 08 2A 00 82 00 84 F0 7F 07
# REAL 1.23
# 09 07 03 31 32 33 45 2D 32
# REAL -0.33
# 09 07 03 2D 33 33 45 2D 32
# REAL { 45 2 31 }
# 09 03 80 1F 2D
# ENUMERATED 5
# 0A 01 05
# ENUMERATED 90000
# 0A 03 01 5F 90
# BMPString 'HENLO BORTHERS'
# 1E 1C 00 48 00 45 00 4E 00 4C 00 4F 00 20 00 42 00 4F 00 52 00 54 00 48 00 45
# 00 52 00 53
# UniversalString 'HENLO BORTHERS'
# 1C 38 00 00 00 48 00 00 00 45 00 00 00 4E 00 00 00 4C 00 00 00 4F 00 00 00 20
# 00 00 00 42 00 00 00 4F 00 00 00 52 00 00 00 54 00 00 00 48 00 00 00 45 00 00
# 00 52 00 00 00 53

# *** CANONICAL ENCODING RULES ***
# BOOLEAN True
# 01 01 FFBOOLEAN False
# 01 01 00
# INTEGER 502 01 05
# INTEGER 90000
# 02 03 01 5F 90
# BITSTRING 101100111000
# 03 03 04 B3 80
# BITSTRING 10110100
# 03 02 00 B4
# OCTET STRING 'HENLO BORTHERS'
# 04 0E 48 45 4E 4C 4F 20 42 4F 52 54 48 45 52 53
# NULL
# 05 00
# OBJECT IDENTIFIER 1.2.0.256.79999.7
# 06 08 2A 00 82 00 84 F0 7F 07
# REAL 1.23
# 09 07 03 31 32 33 45 2D 32
# REAL -0.33
# 09 07 03 2D 33 33 45 2D 32
# REAL { 45 2 31 }
# 09 03 80 1F 2D
# ENUMERATED 5
# 0A 01 05
# ENUMERATED 90000
# 0A 03 01 5F 90
# BMPString 'HENLO BORTHERS'
# 1E 1C 00 48 00 45 00 4E 00 4C 00 4F 00 20 00 42 00 4F 00 52 00 54 00 48 00 45 00 52 00 53


# *** DISTINGUISHED ENCODING RULES ***
# BOOLEAN True
# 01 01 FF
# BOOLEAN False
# 01 01 00
# INTEGER 5
# 02 01 05
# INTEGER 90000
# 02 03 01 5F 90
# BITSTRING 101100111000
# 03 03 04 B3 80
# BITSTRING 10110100
# 03 02 00 B4
# OCTET STRING 'HENLO BORTHERS'
# 04 0E 48 45 4E 4C 4F 20 42 4F 52 54 48 45 52 53
# NULL
# 05 00
# OBJECT IDENTIFIER 1.2.0.256.79999.7
# 06 08 2A 00 82 00 84 F0 7F 07
# REAL 1.23
# 09 07 03 31 32 33 45 2D 32
# REAL -0.33
# 09 07 03 2D 33 33 45 2D 32
# REAL { 45 2 31 }
# 09 03 80 1F 2D
# ENUMERATED 5
# 0A 01 05
# ENUMERATED 90000
# 0A 03 01 5F 90
# BMPString 'HENLO BORTHERS'
# 1E 1C 00 48 00 45 00 4E 00 4C 00 4F 00 20 00 42 00 4F 00 52 00 54 00 48 00 45 00 52 00 53
# UniversalString 'HENLO BORTHERS'
# 1C 38 00 00 00 48 00 00 00 45 00 00 00 4E 00 00 00 4C 00 00 00 4F 00 00 00 20 00 00 00 42 00 00 00 4F 00 00 00 52 00 00 00 54 00 00 00 48 00 00 00 45 00 00 00 52 00 00 00 53