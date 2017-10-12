#!/bin/sh

# CODECS=(der ber cer xer cxer exer per uper cper oer coer jer gser lwer bacnet ser)
    
dmd \
./source/asn1.d \
./source/codec.d \
./source/types/*.d \
./source/types/universal/*.d \
./source/codecs/*.d \
-lib \
-od./build/libraries/ \
-d