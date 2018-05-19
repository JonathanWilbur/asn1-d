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
VERSION=`cat ./version`

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
mkdir -p ./output
mkdir -p ./output/assemblies
mkdir -p ./output/executables
mkdir -p ./output/interfaces
mkdir -p ./output/libraries
mkdir -p ./output/logs
mkdir -p ./output/maps
mkdir -p ./output/objects

echo $ECHOFLAGS "Building the ASN.1 Library (static)... \c"
if dmd \
 ./source/macros.ddoc \
 ./source/asn1/*.d \
 ./source/asn1/types/*.d \
 ./source/asn1/types/universal/*.d \
 ./source/asn1/codecs/*.d \
 -Dd./documentation/html \
 -Hd./output/interfaces \
 -op \
 -of./output/libraries/asn1-${VERSION}.a \
 -Xf./documentation/asn1-${VERSION}.json \
 -lib \
 -inline \
 -release \
 -O \
 -map \
 -v >> ./output/logs/${TIMESTAMP}.log 2>&1; then
    echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
else
    echo $ECHOFLAGS "${RED}Failed. See ./output/logs.${NOCOLOR}"
fi

echo $ECHOFLAGS "Building the ASN.1 Library (shared / dynamic)... \c"
if dmd \
 ./source/asn1/*.d \
 ./source/asn1/types/*.d \
 ./source/asn1/types/universal/*.d \
 ./source/asn1/codecs/*.d \
 -of./output/libraries/asn1-${VERSION}.so \
 -shared \
 -fPIC \
 -inline \
 -release \
 -O \
 -v >> ./output/logs/${TIMESTAMP}.log 2>&1; then
    echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
else
    echo $ECHOFLAGS "${RED}Failed. See ./output/logs.${NOCOLOR}"
fi

for DECODER in $(ls -1 ./source/tools | grep decode_)
do
    EXECUTABLE=$(echo $DECODER | sed "s/_/-/g" | sed "s/\.d//g")
    echo $ECHOFLAGS "Building the ASN.1 Command-Line Tool, ${EXECUTABLE}... \c"
    if dmd \
     -I./output/interfaces/source \
     -L./output/libraries/asn1-${VERSION}.a \
     ./source/tools/decoder_mixin.d \
     ./source/tools/${DECODER} \
     -od./output/objects \
     -of./output/executables/${EXECUTABLE} \
     -inline \
     -release \
     -O \
     -v >> ./output/logs/${TIMESTAMP}.log 2>&1; then
        echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
        chmod +x ./output/executables/${EXECUTABLE}
    else
        echo $ECHOFLAGS "${RED}Failed. See ./output/logs.${NOCOLOR}"
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
     -I./output/interfaces/source \
     -L./output/libraries/asn1-${VERSION}.a \
     ./source/tools/encoder_mixin.d \
     ./source/tools/${ENCODER} \
     -od./output/objects \
     -of./output/executables/${EXECUTABLE} \
     -inline \
     -release \
     -O \
     -v >> ./output/logs/${TIMESTAMP}.log 2>&1; then
        echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
        chmod +x ./output/executables/${EXECUTABLE}
    else
        echo $ECHOFLAGS "${RED}Failed. See ./output/logs.${NOCOLOR}"
    fi
done

mv *.lst ./output/logs 2>/dev/null
mv *.map ./output/maps 2>/dev/null