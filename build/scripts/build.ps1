mkdir .\documentation 2>&1 | Out-Null
mkdir .\documentation\html 2>&1 | Out-Null
mkdir .\build 2>&1 | Out-Null
mkdir .\build\executables 2>&1 | Out-Null
mkdir .\build\interfaces 2>&1 | Out-Null
mkdir .\build\libraries 2>&1 | Out-Null
mkdir .\build\objects 2>&1 | Out-Null

dmd `
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
-Dd".\\documentation\\html\\" `
-Hd".\\build\\interfaces" `
-op `
-of".\\build\\libraries\\asn1.lib" `
-Xf".\\documentation\\asn1.json" `
-lib `
-cov `
-O `
-profile `
-release

# Build decode-ber
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\decode_ber.d `
 -L".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\decode-ber" `
 -O `
 -release

# Build decode-cer
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\decode_cer.d `
 -L".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\decode-cer" `
 -O `
 -release

# Build decode-der
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\decode_der.d `
 -L".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\decode-der" `
 -O `
 -release

# Build encode-ber
dmd `
 -I".\\build\\interfaces\\source" `
 -I".\\build\\interfaces\\source\\codecs" `
 .\source\tools\encode_ber.d `
 -L".\\build\\libraries\\asn1.lib" `
 -of".\\build\\executables\\encode-ber" `
 -O `
 -release

# Delete object files that get created.
# Yes, I tried -o- already. It does not create the executable either.
Remove-Item -path .\build\executables\* -include *.o