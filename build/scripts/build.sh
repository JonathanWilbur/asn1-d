#!/bin/sh
mkdir -p ./documentation
mkdir -p ./documentation/html
mkdir -p ./build
mkdir -p ./build/executables
mkdir -p ./build/interfaces
mkdir -p ./build/libraries
mkdir -p ./build/objects
    
dmd \
./source/asn1.d \
./source/codec.d \
./source/types/*.d \
./source/types/universal/*.d \
./source/codecs/*.d \
-Dd./documentation/html \
-Hd./build/interfaces \
-op \
-of./build/libraries/asn1.lib \
-Xf./documentation/asn1.json \
-lib \
-cov \
-O \
-profile \
-release

# Build decode-ber
dmd \
 -I./build/interfaces/source \
 -I./build/interfaces/source/codecs \
 ./source/tools/decode_ber.d \
 -L./build/libraries/asn1.lib \
 -of./build/executables/decode-ber \
 -O \
 -release

# Build decode-cer
dmd \
 -I./build/interfaces/source \
 -I./build/interfaces/source/codecs \
 ./source/tools/decode_cer.d \
 -L./build/libraries/asn1.lib \
 -of./build/executables/decode-cer \
 -O \
 -release

# Build decode-der
dmd \
 -I./build/interfaces/source \
 -I./build/interfaces/source/codecs \
 ./source/tools/decode_der.d \
 -L./build/libraries/asn1.lib \
 -of./build/executables/decode-der \
 -O \
 -release

# Delete object files that get created.
# Yes, I tried -o- already. It does not create the executable either.
rm -f ./build/executables/*.o