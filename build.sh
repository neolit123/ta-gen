#!/bin/sh

VERSION_TAGEN=`cat ./VERSION 2> /dev/null`
if [ ! $VERSION_TAGEN ]; then
	echo "ERROR: cannot find version file"
	exit 1;
fi
echo "found VERSION file: $VERSION_TAGEN"

BUILD_COMMAND="$AIR_SDK_BIN""mxmlc +configname=air ./src/Main.as -output ./bin/ta-gen.swf -library-path+=./lib $@"

TMPFILE=./adl.tmp

"$AIR_SDK_BIN"adl 2> /dev/null > $TMPFILE
VERSION_ADL=`sed '2q;d' $TMPFILE`

VERSION_ADL=`grep Version $TMPFILE | cut -c8-12`
CMD_RES=`rm -f $TMPFILE`

if [ ! $VERSION_ADL ]; then
	echo "ERROR: cannot find ADL or obtain it's version"
	exit 1;
else
	echo found ADL version: $VERSION_ADL
	./writedesc.sh $VERSION_ADL $VERSION_TAGEN
fi

echo building...
CMD_RES=`$BUILD_COMMAND > /dev/null`
