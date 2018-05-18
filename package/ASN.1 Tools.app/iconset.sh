#!/bin/sh
# Source: https://stackoverflow.com/questions/12306223/how-to-manually-create-icns-files-using-iconutil#20703594

mkdir ASN.1-Tools.iconset
sips -z 16 16     Icon512.png --out ASN.1-Tools.iconset/icon_16x16.png
sips -z 32 32     Icon512.png --out ASN.1-Tools.iconset/icon_16x16@2x.png
sips -z 32 32     Icon512.png --out ASN.1-Tools.iconset/icon_32x32.png
sips -z 64 64     Icon512.png --out ASN.1-Tools.iconset/icon_32x32@2x.png
sips -z 128 128   Icon512.png --out ASN.1-Tools.iconset/icon_128x128.png
sips -z 256 256   Icon512.png --out ASN.1-Tools.iconset/icon_128x128@2x.png
sips -z 256 256   Icon512.png --out ASN.1-Tools.iconset/icon_256x256.png
sips -z 512 512   Icon512.png --out ASN.1-Tools.iconset/icon_256x256@2x.png
sips -z 512 512   Icon512.png --out ASN.1-Tools.iconset/icon_512x512.png
iconutil -c icns ASN.1-Tools.iconset
rm -R ASN.1-Tools.iconset
mv ASN.1-Tools.icns Contents/Resources/ASN.1-Tools.icns