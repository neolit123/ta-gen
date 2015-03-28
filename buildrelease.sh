#!/bin/sh

./build.sh

TMPFILE=./adl.tmp
VERSION_TAGEN=`cat ./VERSION 2> /dev/null`
"$AIR_SDK_BIN"adl 2> /dev/null > $TMPFILE
VERSION_ADL=`sed '2q;d' $TMPFILE`
VERSION_ADL=`grep Version $TMPFILE | cut -c9-12`
CMD_RES=`rm -f $TMPFILE`

ZIP_FILE="ta-gen_v""$VERSION_TAGEN""_air"$VERSION_ADL".zip"
echo "creating release "$ZIP_FILE"..."
7za a "./release/"$ZIP_FILE ./bin/* ./README.md ./VERSION ./LICENSE > /dev/null
