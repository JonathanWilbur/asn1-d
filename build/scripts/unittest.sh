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

if [ "$(uname)" == "Darwin" ]; then
	ECHOFLAGS=""
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	ECHOFLAGS="-e"
fi

echo $ECHOFLAGS "Building the ASN.1 Unit Testing Executable... \c"
if dmd \
 ./source/asn1/*.d \
 ./source/asn1/types/*.d \
 ./source/asn1/types/universal/*.d \
 ./source/asn1/codecs/*.d \
 -of./unittest \
 -unittest \
 -main \
 -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
    echo $ECHOFLAGS "${GREEN}Done. Run ./unittest to test.${NOCOLOR}"
else
    echo $ECHOFLAGS "${RED}Failed. See ./build/logs.${NOCOLOR}"
fi