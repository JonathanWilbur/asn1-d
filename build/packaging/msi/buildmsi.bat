@echo off
mkdir build\packages > nul 2>&1
mkdir build\packages\msi > nul 2>&1
"C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe" -out build\packaging\msi\asn1.wixobj build\packaging\msi\asn1.wxs
"C:\Program Files (x86)\WiX Toolset v3.11\bin\light.exe" -spdb -ext WixUIExtension -out build\packages\msi\asn1.msi build\packaging\msi\asn1.wixobj