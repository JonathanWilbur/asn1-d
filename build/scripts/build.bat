@echo off
REM NOTE:
REM The command-line tools are all compiled with the specific inclusion of the
REM file `.\source\asn1\types\oidtype.d`. This is because of a compiler bug, in
REM which the interface for `oidtype.d` is not including the method body for the
REM `descriptor` properties. I believe this is related to this Bugzilla Bug:
REM
REM https://issues.dlang.org/show_bug.cgi?id=18620
REM
REM but there are other bugs like that going back to 2014, so it will probably
REM not be fixed just by changing your DMD compiler version.
REM 
mkdir .\documentation > nul 2>&1
mkdir .\documentation\html > nul 2>&1
mkdir .\documentation\links > nul 2>&1
mkdir .\build > nul 2>&1
mkdir .\build\assemblies > nul 2>&1
mkdir .\build\executables > nul 2>&1
mkdir .\build\interfaces > nul 2>&1
mkdir .\build\libraries > nul 2>&1
mkdir .\build\logs > nul 2>&1
mkdir .\build\maps > nul 2>&1
mkdir .\build\objects > nul 2>&1
mkdir .\build\scripts > nul 2>&1

set version="2.4.1"

echo|set /p="Building the ASN.1 Library (static)... "
dmd ^
 .\source\macros.ddoc ^
 .\source\asn1\constants.d ^
 .\source\asn1\compiler.d ^
 .\source\asn1\codec.d ^
 .\source\asn1\interfaces.d ^
 .\source\asn1\types\alltypes.d ^
 .\source\asn1\types\identification.d ^
 .\source\asn1\types\oidtype.d ^
 .\source\asn1\types\universal\characterstring.d ^
 .\source\asn1\types\universal\embeddedpdv.d ^
 .\source\asn1\types\universal\external.d ^
 .\source\asn1\types\universal\objectidentifier.d ^
 .\source\asn1\codecs\ber.d ^
 .\source\asn1\codecs\cer.d ^
 .\source\asn1\codecs\der.d ^
 -Dd.\documentation\html\ ^
 -Hd.\build\interfaces ^
 -op ^
 -of.\build\libraries\asn1-%version%.a ^
 -Xf.\documentation\asn1-%version%.json ^
 -lib ^
 -O ^
 -release ^
 -d
echo Done.

echo|set /p="Building the ASN.1 Library (shared / dynamic)... "
dmd ^
 .\source\asn1\constants.d ^
 .\source\asn1\compiler.d ^
 .\source\asn1\codec.d ^
 .\source\asn1\interfaces.d ^
 .\source\asn1\types\alltypes.d ^
 .\source\asn1\types\identification.d ^
 .\source\asn1\types\oidtype.d ^
 .\source\asn1\types\universal\characterstring.d ^
 .\source\asn1\types\universal\embeddedpdv.d ^
 .\source\asn1\types\universal\external.d ^
 .\source\asn1\types\universal\objectidentifier.d ^
 .\source\asn1\codecs\ber.d ^
 .\source\asn1\codecs\cer.d ^
 .\source\asn1\codecs\der.d ^
 -of.\build\libraries\asn1-%version%.dll ^
 -lib ^
 -shared ^
 -O ^
 -inline ^
 -release ^
 -d
echo Done.

echo|set /p="Building the ASN.1 Command-Line Tool, decode-ber... "
dmd ^
 .\source\asn1\types\oidtype.d ^
 -I".\\build\\interfaces\\source" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_ber.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\decode-ber" ^
 -O ^
 -release ^
 -inline ^
 -d
echo Done.

echo|set /p="Building the ASN.1 Command-Line Tool, decode-cer... "
dmd ^
 .\source\asn1\types\oidtype.d ^
 -I".\\build\\interfaces\\source" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_cer.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\decode-cer" ^
 -O ^
 -release ^
 -inline ^
 -d
echo Done.

echo|set /p="Building the ASN.1 Command-Line Tool, decode-der... "
dmd ^
 .\source\asn1\types\oidtype.d ^
 -I".\\build\\interfaces\\source" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_der.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\decode-der" ^
 -O ^
 -release ^
 -inline ^
 -d
echo Done.

echo|set /p="Building the ASN.1 Command-Line Tool, encode-ber... "
dmd ^
 .\source\asn1\types\oidtype.d ^
 -I".\\build\\interfaces\\source" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_ber.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\encode-ber" ^
 -O ^
 -release ^
 -inline ^
 -d
echo Done.

echo|set /p="Building the ASN.1 Command-Line Tool, encode-cer... "
dmd ^
 .\source\asn1\types\oidtype.d ^
 -I".\\build\\interfaces\\source" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_cer.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\encode-cer" ^
 -O ^
 -release ^
 -inline ^
 -d
echo Done.

echo|set /p="Building the ASN.1 Command-Line Tool, encode-der... "
dmd ^
 .\source\asn1\types\oidtype.d ^
 -I".\\build\\interfaces\\source" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_der.d ^
 -L+".\\build\\libraries\\asn1-%version%.a" ^
 -od".\\build\\objects" ^
 -of".\\build\\executables\\encode-der" ^
 -O ^
 -release ^
 -inline ^
 -d
echo Done.