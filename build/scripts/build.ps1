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

$version = "2.3.3"

Write-Host "Building the ASN.1 Library (static)... " -NoNewLine
dmd `
.\source\macros.ddoc `
.\source\asn1\constants.d `
.\source\asn1\compiler.d `
.\source\asn1\codec.d `
.\source\asn1\interfaces.d `
.\source\asn1\types\alltypes.d `
.\source\asn1\types\identification.d `
.\source\asn1\types\oidtype.d `
.\source\asn1\types\universal\characterstring.d `
.\source\asn1\types\universal\embeddedpdv.d `
.\source\asn1\types\universal\external.d `
.\source\asn1\types\universal\objectidentifier.d `
.\source\asn1\codecs\ber.d `
.\source\asn1\codecs\cer.d `
.\source\asn1\codecs\der.d `
-Dd".\\documentation\\html\\" `
-Hd".\\build\\interfaces" `
-op `
-of".\\build\\libraries\\asn1-$version.a" `
-Xf".\\documentation\\asn1-$version.json" `
-lib `
-O `
-release `
-d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Library (shared / dynamic)... " -NoNewLine
dmd `
.\source\asn1\constants.d `
.\source\asn1\compiler.d `
.\source\asn1\codec.d `
.\source\asn1\interfaces.d `
.\source\asn1\types\alltypes.d `
.\source\asn1\types\identification.d `
.\source\asn1\types\oidtype.d `
.\source\asn1\types\universal\characterstring.d `
.\source\asn1\types\universal\embeddedpdv.d `
.\source\asn1\types\universal\external.d `
.\source\asn1\types\universal\objectidentifier.d `
.\source\asn1\codecs\ber.d `
.\source\asn1\codecs\cer.d `
.\source\asn1\codecs\der.d `
-of".\\build\\libraries\\asn1-$version.dll" `
-lib `
-shared `
-O `
-inline `
-release `
-d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, decode-ber... " -NoNewLine
dmd `
 -I".\\build\\interfaces\\source" `
 .\source\tools\decoder_mixin.d `
 .\source\tools\decode_ber.d `
 -L+".\\build\\libraries\\asn1-$version.a" `
 -od".\\build\\objects" `
 -of".\\build\\executables\\decode-ber" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green


Write-Host "Building the ASN.1 Command-Line Tool, decode-cer... " -NoNewLine
dmd `
 -I".\\build\\interfaces\\source" `
 .\source\tools\decoder_mixin.d `
 .\source\tools\decode_cer.d `
 -L+".\\build\\libraries\\asn1-$version.a" `
 -od".\\build\\objects" `
 -of".\\build\\executables\\decode-cer" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, decode-der... " -NoNewLine
dmd `
 -I".\\build\\interfaces\\source" `
 .\source\tools\decoder_mixin.d `
 .\source\tools\decode_der.d `
 -L+".\\build\\libraries\\asn1-$version.a" `
 -od".\\build\\objects" `
 -of".\\build\\executables\\decode-der" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, encode-ber... " -NoNewLine
dmd `
 -I".\\build\\interfaces\\source" `
 .\source\tools\encoder_mixin.d `
 .\source\tools\encode_ber.d `
 -L+".\\build\\libraries\\asn1-$version.a" `
 -od".\\build\\objects" `
 -of".\\build\\executables\\encode-ber" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, encode-cer... " -NoNewLine
dmd `
 -I".\\build\\interfaces\\source" `
 .\source\tools\encoder_mixin.d `
 .\source\tools\encode_cer.d `
 -L+".\\build\\libraries\\asn1-$version.a" `
 -od".\\build\\objects" `
 -of".\\build\\executables\\encode-cer" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, encode-der... " -NoNewLine
dmd `
 -I".\\build\\interfaces\\source" `
 .\source\tools\encoder_mixin.d `
 .\source\tools\encode_der.d `
 -L+".\\build\\libraries\\asn1-$version.a" `
 -od".\\build\\objects" `
 -of".\\build\\executables\\encode-der" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green