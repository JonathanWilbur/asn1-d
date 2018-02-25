#!/bin/sh
#
# NOTE:
# This script assumes that your terminal supports ANSI Escape Codes and colors.
# It should not fail if your terminal does not support it--the output will just
# look a bit garbled.
#
GREEN='\033[32m'
RED='\033[31m'
NOCOLOR='\033[0m'
TIMESTAMP=$(date '+%Y-%m-%d@%H:%M:%S')
VERSION="2.2.0"

if [ "$(uname)" == "Darwin" ]; then
	ECHOFLAGS=""
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	ECHOFLAGS="-e"
fi

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

echo $ECHOFLAGS "Building the ASN.1 Library (static)... \c"
if dmd \
 ./source/macros.ddoc \
 ./source/asn1/*.d \
 ./source/asn1/types/*.d \
 ./source/asn1/types/universal/*.d \
 ./source/asn1/codecs/*.d \
 -Dd./documentation/html \
 -Hd./build/interfaces \
 -op \
 -of./build/libraries/asn1-${VERSION}.a \
 -Xf./documentation/asn1-${VERSION}.json \
 -lib \
 -inline \
 -release \
 -O \
 -map \
 -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
    echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
else
    echo $ECHOFLAGS "${RED}Failed. See ./build/logs.${NOCOLOR}"
fi

echo $ECHOFLAGS "Building the ASN.1 Library (shared / dynamic)... \c"
if dmd \
 ./source/asn1/*.d \
 ./source/asn1/types/*.d \
 ./source/asn1/types/universal/*.d \
 ./source/asn1/codecs/*.d \
 -of./build/libraries/asn1-${VERSION}.so \
 -shared \
 -fPIC \
 -inline \
 -release \
 -O \
 -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
    echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
else
    echo $ECHOFLAGS "${RED}Failed. See ./build/logs.${NOCOLOR}"
fi

for DECODER in $(ls -1 ./source/tools | grep decode_)
do
    EXECUTABLE=$(echo $DECODER | sed "s/_/-/g" | sed "s/\.d//g")
    echo $ECHOFLAGS "Building the ASN.1 Command-Line Tool, ${EXECUTABLE}... \c"
    if dmd \
     -I./build/interfaces/source \
     -L./build/libraries/asn1-${VERSION}.a \
     ./source/tools/decoder_mixin.d \
     ./source/tools/${DECODER} \
     -od./build/objects \
     -of./build/executables/${EXECUTABLE} \
     -inline \
     -release \
     -O \
     -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
        echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
        chmod +x ./build/executables/${EXECUTABLE}
    else
        echo $ECHOFLAGS "${RED}Failed. See ./build/logs.${NOCOLOR}"
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
    echo $ECHOFLAGS "Building the ASN.1 Command-Line Tool, ${EXECUTABLE}... \c"
    if dmd \
     -I./build/interfaces/source \
     -L./build/libraries/asn1-${VERSION}.a \
     ./source/tools/encoder_mixin.d \
     ./source/tools/${ENCODER} \
     -od./build/objects \
     -of./build/executables/${EXECUTABLE} \
     -inline \
     -release \
     -O \
     -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
        echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
        chmod +x ./build/executables/${EXECUTABLE}
    else
        echo $ECHOFLAGS "${RED}Failed. See ./build/logs.${NOCOLOR}"
    fi
done

mv *.lst ./build/logs 2>/dev/null
mv *.map ./build/maps 2>/dev/null