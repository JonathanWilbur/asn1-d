@echo off
mkdir .\documentation > nul
mkdir .\documentation\html > nul
mkdir .\build > nul
mkdir .\build\executables > nul
mkdir .\build\interfaces > nul
mkdir .\build\libraries > nul
mkdir .\build\objects > nul

dmd ^
.\source\asn1.d ^
.\source\codec.d ^
.\source\types\alltypes.d ^
.\source\types\identification.d ^
.\source\types\oidtype.d ^
.\source\types\universal\characterstring.d ^
.\source\types\universal\embeddedpdv.d ^
.\source\types\universal\external.d ^
.\source\types\universal\objectidentifier.d ^
.\source\codecs\ber.d ^
-Dd.\documentation\html\ ^
-Hf.\build\interfaces\asn1.di ^
-of.\build\libraries\asn1.lib ^
-Xf.\documentation\asn1.json ^
-lib ^
-cov ^
-O ^
-profile ^
-release