mkdir .\documentation 2>&1 | Out-Null
mkdir .\documentation\html 2>&1 | Out-Null
mkdir .\documentation\links 2>&1 | Out-Null
mkdir .\build 2>&1 | Out-Null
mkdir .\build\assemblies 2>&1 | Out-Null
mkdir .\build\executables 2>&1 | Out-Null
mkdir .\build\interfaces 2>&1 | Out-Null
mkdir .\build\libraries 2>&1 | Out-Null
mkdir .\build\logs 2>&1 | Out-Null
mkdir .\build\maps 2>&1 | Out-Null
mkdir .\build\objects 2>&1 | Out-Null
mkdir .\build\scripts 2>&1 | Out-Null

echo "Building statically-linked library"
dmd `
.\source\macros.ddoc `
.\source\asn1.d `
.\source\codec.d `
.\source\interfaces.d `
.\source\types\alltypes.d `
.\source\types\identification.d `
.\source\types\oidtype.d `
.\source\types\universal\characterstring.d `
.\source\types\universal\embeddedpdv.d `
.\source\types\universal\external.d `
.\source\types\universal\objectidentifier.d `
.\source\codecs\ber.d `
.\source\codecs\cer.d `
.\source\codecs\der.d `
-Dd".\\documentation\\html\\" `
-Hd".\\build\\interfaces" `
-op `
-of".\\build\\libraries\\asn1.lib" `
-Xf".\\documentation\\asn1.json" `
-lib `
-O `
-release `
-d

echo "Building dynamically-linked library"
dmd `
.\source\macros.ddoc `
.\source\asn1.d `
.\source\codec.d `
.\source\interfaces.d `
.\source\types\alltypes.d `
.\source\types\identification.d `
.\source\types\oidtype.d `
.\source\types\universal\characterstring.d `
.\source\types\universal\embeddedpdv.d `
.\source\types\universal\external.d `
.\source\types\universal\objectidentifier.d `
.\source\codecs\ber.d `
.\source\codecs\cer.d `
.\source\codecs\der.d `
-of".\\build\\libraries\\asn1.dll" `
-shared `
-fPIC `
-O `
-inline `
-release `
-d

echo "Building decode-ber"
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\decoder_mixin.d `
 .\source\tools\decode_ber.d `
 -L+".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\decode-ber" `
 -O `
 -release `
 -inline `
 -d

echo "Building decode-cer"
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\decoder_mixin.d `
 .\source\tools\decode_cer.d `
 -L+".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\decode-cer" `
 -O `
 -release `
 -inline `
 -d

echo "Building decode-der"
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\decoder_mixin.d `
 .\source\tools\decode_der.d `
 -L+".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\decode-der" `
 -O `
 -release `
 -inline `
 -d

echo "Building encode-ber"
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\encoder_mixin.d `
 .\source\tools\encode_ber.d `
 -L+".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\encode-ber" `
 -O `
 -release `
 -inline `
 -d

echo "Building encode-cer"
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\encoder_mixin.d `
 .\source\tools\encode_cer.d `
 -L+".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\encode-cer" `
 -O `
 -release `
 -inline `
 -d

echo "Building encode-der"
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\encoder_mixin.d `
 .\source\tools\encode_der.d `
 -L+".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\encode-der" `
 -O `
 -release `
 -inline `
 -d

# Delete object files that get created.
# Yes, I tried -o- already. It does not create the executable either.
Remove-Item -path .\build\executables\* -include *.o