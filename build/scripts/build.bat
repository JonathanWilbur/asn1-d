@echo off
mkdir .\documentation > nul
mkdir .\documentation\html > nul
mkdir .\build > nul
mkdir .\build\executables > nul
mkdir .\build\interfaces > nul
mkdir .\build\libraries > nul
mkdir .\build\objects > nul

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
-Dd.\documentation\html\ ^
-Hd.\build\interfaces ^
-op ^
-of.\build\libraries\asn1.lib ^
-Xf.\documentation\asn1.json ^
-lib ^
-O ^
-release ^
-d

# Build decode-ber
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_ber.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\decode-ber" ^
 -O ^
 -release ^
 -d

# Build decode-cer
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_cer.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\decode-cer" ^
 -O ^
 -release ^
 -d

# Build decode-der
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\decoder_mixin.d ^
 .\source\tools\decode_der.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\decode-der" ^
 -O ^
 -release ^
 -d

# Build encode-ber
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_ber.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\encode-ber" ^
 -O ^
 -release ^
 -d

# Build encode-cer
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_cer.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\encode-cer" ^
 -O ^
 -release ^
 -d

# Build encode-der
dmd ^
 -I".\\build\\interfaces\\source" ^
 -I".\\build\\interfaces\\source\\codecs" ^
 .\source\tools\encoder_mixin.d ^
 .\source\tools\encode_der.d ^
 -L+".\\build\\libraries\\asn1.lib" ^
 -of".\\build\\executables\\encode-der" ^
 -O ^
 -release ^
 -d

# Delete object files that get created.
# Yes, I tried -o- already. It does not create the executable either.
del .\build\executables\*.o