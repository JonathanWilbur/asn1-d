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

echo Building the static library
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
-of.\build\libraries\asn1.lib ^
-Xf.\documentation\asn1.json ^
-lib ^
-O ^
-release ^
-d

echo Building the dynamically-linked library
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
-of.\build\libraries\asn1.dll ^
-shared ^
-fPIC ^
-O ^
-inline ^
-release ^
-d

REM Build decode-ber
echo Building decode-ber
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_ber.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\decode-ber" ^
 -O ^
 -release ^
 -inline ^
 -d

echo Building decode-cer
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_cer.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\decode-cer" ^
 -O ^
 -release ^
 -inline ^
 -d

echo Building decode-der
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_der.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\decode-der" ^
 -O ^
 -release ^
 -inline ^
 -d

echo Building encode-ber
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_ber.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\encode-ber" ^
 -O ^
 -release ^
 -inline ^
 -d

echo Building encode-cer
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_cer.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\encode-cer" ^
 -O ^
 -release ^
 -inline ^
 -d

echo Building encode-der
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_der.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\encode-der" ^
 -O ^
 -release ^
 -inline ^
 -d

REM Delete object files that get created.
REM Yes, I tried -o- already. It does not create the executable either.
del .\build\executables\*.o
REM TODO: Move statements