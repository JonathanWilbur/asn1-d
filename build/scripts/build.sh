#!/bin/sh
mkdir ./documentation &> /dev/null
mkdir ./documentation/html &> /dev/null
mkdir ./build &> /dev/null
mkdir ./build/executables &> /dev/null
mkdir ./build/interfaces &> /dev/null
mkdir ./build/libraries &> /dev/null
mkdir ./build/objects &> /dev/null
    
dmd \
./source/asn1.d \
./source/codec.d \
./source/types/*.d \
./source/types/universal/*.d \
./source/codecs/*.d \
-Dd./documentation/html \
-Hf./build/interfaces/asn1.di \
-of./build/libraries/asn1.lib \
-Xf./documentation/asn1.json \
-lib \
-cov \
-O \
-profile \
-release