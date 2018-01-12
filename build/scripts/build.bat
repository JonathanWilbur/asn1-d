@echo off
mkdir .\documentation > nul
mkdir .\documentation\html > nul
mkdir .\documentation\links > nul
mkdir .\build > nul
mkdir .\build\assemblies > nul
mkdir .\build\executables > nul
mkdir .\build\interfaces > nul
mkdir .\build\libraries > nul
mkdir .\build\logs > nul
mkdir .\build\maps > nul
mkdir .\build\objects > nul
mkdir .\build\scripts > nul

set version="1.0.0"

echo "Building the ASN.1 Library (static)... \c"
dmd ^
 .\source\macros.ddoc ^
 .\source\asn1.d ^
 .\source\codec.d ^
 .\source\interfaces.d ^
 .\source\types\alltypes.d ^
 .\source\types\identification.d ^
 .\source\types\oidtype.d ^
 .\source\types\universal\characterstring.d ^
 .\source\types\universal\embeddedpdv.d ^
 .\source\types\universal\external.d ^
 .\source\types\universal\objectidentifier.d ^
 .\source\codecs\ber.d ^
 .\source\codecs\cer.d ^
 .\source\codecs\der.d ^
 -Dd.\documentation\html\ ^
 -Hd.\build\interfaces ^
 -op ^
 -of.\build\libraries\asn1-%version%.a ^
 -Xf.\documentation\asn1-%version%.json ^
 -lib ^
 -O ^
 -release ^
 -d
echo "\033[0;32mDone.\033[0m"

echo "Building the ASN.1 Library (shared / dynamic)... \c"
dmd ^
 .\source\asn1.d ^
 .\source\codec.d ^
 .\source\interfaces.d ^
 .\source\types\alltypes.d ^
 .\source\types\identification.d ^
 .\source\types\oidtype.d ^
 .\source\types\universal\characterstring.d ^
 .\source\types\universal\embeddedpdv.d ^
 .\source\types\universal\external.d ^
 .\source\types\universal\objectidentifier.d ^
 .\source\codecs\ber.d ^
 .\source\codecs\cer.d ^
 .\source\codecs\der.d ^
 -of.\build\libraries\asn1-%version%.dll ^
 -shared ^
 -fPIC ^
 -O ^
 -inline ^
 -release ^
 -d
echo "\033[0;32mDone.\033[0m"

echo "Building the ASN.1 Command-Line Tool, decode-ber... \c"
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_ber.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\decode-ber" ^
 -O ^
 -release ^
 -inline ^
 -d
echo "\033[0;32mDone.\033[0m"

echo "Building the ASN.1 Command-Line Tool, decode-cer... \c"
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_cer.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\decode-cer" ^
 -O ^
 -release ^
 -inline ^
 -d
echo "\033[0;32mDone.\033[0m"

echo "Building the ASN.1 Command-Line Tool, decode-der... \c"
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_der.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\decode-der" ^
 -O ^
 -release ^
 -inline ^
 -d
echo "\033[0;32mDone.\033[0m"

echo "Building the ASN.1 Command-Line Tool, encode-ber... \c"
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_ber.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\encode-ber" ^
 -O ^
 -release ^
 -inline ^
 -d
echo "\033[0;32mDone.\033[0m"

echo "Building the ASN.1 Command-Line Tool, encode-cer... \c"
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_cer.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\encode-cer" ^
 -O ^
 -release ^
 -inline ^
 -d
echo "\033[0;32mDone.\033[0m"

echo "Building the ASN.1 Command-Line Tool, encode-der... \c"
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_der.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\encode-der" ^
 -O ^
 -release ^
 -inline ^
 -d
echo "\033[0;32mDone.\033[0m"