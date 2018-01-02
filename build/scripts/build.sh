#!/bin/sh
#
# NOTE:
# This script assumes that your terminal supports ANSI Escape Codes and colors.
# It should not fail if your terminal does not support it--the output will just
# look a bit garbled.
#
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NOCOLOR='\033[0m'
TIMESTAMP=$(date '+%Y-%m-%d@%H:%M:%S')

# Unfortunately, because this is running in a shell script, brace expansion
# might not work, so I can't create all the necessary directories "the cool
# way." See this StackOverflow question that addresses my problem:
# https://stackoverflow.com/questions/40164660/bash-brace-expansion-not-working-on-dockerfile-run-command
mkdir -p ./documentation
mkdir -p ./documentation/html
mkdir -p ./documentation/links
mkdir -p ./build
mkdir -p ./build/assemblies
mkdir -p ./build/executables
mkdir -p ./build/interfaces
mkdir -p ./build/libraries
mkdir -p ./build/logs
mkdir -p ./build/maps
mkdir -p ./build/objects
mkdir -p ./build/scripts

echo "Building the ASN.1 Library (static)... \c"
if dmd \
 ./source/asn1.d \
 ./source/codec.d \
 ./source/interfaces.d \
 ./source/types/*.d \
 ./source/types/universal/*.d \
 ./source/codecs/*.d \
 -Dd./documentation/html \
 -Hd./build/interfaces \
 -op \
 -of./build/libraries/asn1.lib \
 -Xf./documentation/asn1.json \
 -lib \
 -inline \
 -release \
 -O \
 -map \
 -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
    echo "${GREEN}Done.${NOCOLOR}"
else
    echo "${RED}Failed. See ./build/logs.${NOCOLOR}"
fi

echo "Building the ASN.1 Library (shared / dynamic)... \c"
if dmd \
 ./source/asn1.d \
 ./source/codec.d \
 ./source/interfaces.d \
 ./source/types/*.d \
 ./source/types/universal/*.d \
 ./source/codecs/*.d \
 -of./build/libraries/asn1.so \
 -shared \
 -fPIC \
 -inline \
 -release \
 -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
    echo "${GREEN}Done.${NOCOLOR}"
else
    echo "${RED}Failed. See ./build/logs.${NOCOLOR}"
fi

for DECODER in $(ls -1 ./source/tools | grep decode_)
do
    EXECUTABLE=$(echo $DECODER | sed "s/_/-/g" | sed "s/\.d//g")
    echo "Building the ASN.1 Command-Line Tool, ${EXECUTABLE}... \c"
    if dmd \
     -I./build/interfaces/source \
     -I./build/interfaces/source/codecs \
     -L./build/libraries/asn1.lib \
     ./source/tools/decoder_mixin.d \
     ./source/tools/${DECODER} \
     -of./build/executables/${EXECUTABLE} \
     -inline \
     -release \
     -O \
     -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
        echo "${GREEN}Done.${NOCOLOR}"
    else
        echo "${RED}Failed. See ./build/logs.${NOCOLOR}"
    fi
done

# NOTE:
# Supplying the -lphobos2 flag to the linker is a hard-coded feature of the DMD
# compiler. It is not specified in any configuration file.
# To compile other libraries in addition to Phobos, you must send both the -L
# and -l flags to the linker, indicating what folder to search, and what file
# to use, respectively.

for ENCODER in $(ls -1 ./source/tools | grep encode_)
do
    EXECUTABLE=$(echo $ENCODER | sed "s/_/-/g" | sed "s/\.d//g")
    echo "Building the ASN.1 Command-Line Tool, ${EXECUTABLE}... \c"
    if dmd \
     -I./build/interfaces/source \
     -I./build/interfaces/source/codecs \
     -L./build/libraries/asn1.lib \
     ./source/tools/encoder_mixin.d \
     ./source/tools/${ENCODER} \
     -of./build/executables/${EXECUTABLE} \
     -inline \
     -release \
     -O \
     -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
        echo "${GREEN}Done.${NOCOLOR}"
    else
        echo "${RED}Failed. See ./build/logs.${NOCOLOR}"
    fi
done

# Delete object files that get created.
# Yes, I tried -o- already. It does not create the executable either.
rm -f ./build/executables/*.o
mv *.lst ./build/logs
# mv *.map ./build/maps