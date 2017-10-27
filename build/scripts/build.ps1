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
.\source\types\alltypes.d `
.\source\types\identification.d `
.\source\types\oidtype.d `
.\source\types\universal\characterstring.d `
.\source\types\universal\embeddedpdv.d `
.\source\types\universal\external.d `
.\source\types\universal\objectidentifier.d `
.\source\codecs\ber.d `
-Dd".\\documentation\\html\\" `
-Hf".\\build\\interfaces\\asn1.di" `
-of".\\build\\libraries\\asn1.lib" `
-Xf".\\documentation\\asn1.json" `
-lib `
-cov `
-O `
-profile `
-release