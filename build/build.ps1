# NOTE:
# The command-line tools are all compiled with the specific inclusion of the
# file `.\source\asn1\types\oidtype.d`. This is because of a compiler bug, in
# which the interface for `oidtype.d` is not including the method body for the
# `descriptor` properties. I believe this is related to this Bugzilla Bug:
#
# https://issues.dlang.org/show_bug.cgi?id=18620
#
# but there are other bugs like that going back to 2014, so it will probably
# not be fixed just by changing your DMD compiler version.
# 
mkdir .\documentation 2>&1 | Out-Null
mkdir .\documentation\html 2>&1 | Out-Null
mkdir .\documentation\links 2>&1 | Out-Null
mkdir .\output 2>&1 | Out-Null
mkdir .\output\assemblies 2>&1 | Out-Null
mkdir .\output\executables 2>&1 | Out-Null
mkdir .\output\interfaces 2>&1 | Out-Null
mkdir .\output\libraries 2>&1 | Out-Null
mkdir .\output\maps 2>&1 | Out-Null
mkdir .\output\objects 2>&1 | Out-Null

$version = Get-Content .\version -Raw

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
-Hd".\\output\\interfaces" `
-op `
-of".\\output\\libraries\\asn1-$version.a" `
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
-of".\\output\\libraries\\asn1-$version.dll" `
-lib `
-shared `
-O `
-inline `
-release `
-d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, decode-ber... " -NoNewLine
dmd `
 .\source\asn1\types\oidtype.d `
 -I".\\output\\interfaces\\source" `
 .\source\tools\decoder_mixin.d `
 .\source\tools\decode_ber.d `
 -L+".\\output\\libraries\\asn1-$version.a" `
 -od".\\output\\objects" `
 -of".\\output\\executables\\decode-ber" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green


Write-Host "Building the ASN.1 Command-Line Tool, decode-cer... " -NoNewLine
dmd `
 .\source\asn1\types\oidtype.d `
 -I".\\output\\interfaces\\source" `
 .\source\tools\decoder_mixin.d `
 .\source\tools\decode_cer.d `
 -L+".\\output\\libraries\\asn1-$version.a" `
 -od".\\output\\objects" `
 -of".\\output\\executables\\decode-cer" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, decode-der... " -NoNewLine
dmd `
 .\source\asn1\types\oidtype.d `
 -I".\\output\\interfaces\\source" `
 .\source\tools\decoder_mixin.d `
 .\source\tools\decode_der.d `
 -L+".\\output\\libraries\\asn1-$version.a" `
 -od".\\output\\objects" `
 -of".\\output\\executables\\decode-der" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, encode-ber... " -NoNewLine
dmd `
 .\source\asn1\types\oidtype.d `
 -I".\\output\\interfaces\\source" `
 .\source\tools\encoder_mixin.d `
 .\source\tools\encode_ber.d `
 -L+".\\output\\libraries\\asn1-$version.a" `
 -od".\\output\\objects" `
 -of".\\output\\executables\\encode-ber" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, encode-cer... " -NoNewLine
dmd `
 .\source\asn1\types\oidtype.d `
 -I".\\output\\interfaces\\source" `
 .\source\tools\encoder_mixin.d `
 .\source\tools\encode_cer.d `
 -L+".\\output\\libraries\\asn1-$version.a" `
 -od".\\output\\objects" `
 -of".\\output\\executables\\encode-cer" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the ASN.1 Command-Line Tool, encode-der... " -NoNewLine
dmd `
 .\source\asn1\types\oidtype.d `
 -I".\\output\\interfaces\\source" `
 .\source\tools\encoder_mixin.d `
 .\source\tools\encode_der.d `
 -L+".\\output\\libraries\\asn1-$version.a" `
 -od".\\output\\objects" `
 -of".\\output\\executables\\encode-der" `
 -O `
 -release `
 -inline `
 -d
Write-Host "Done." -ForegroundColor Green