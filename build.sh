#!/bin/sh

VERSION_TAGEN=1.4
BUILD_COMMAND="mxmlc +configname=air ./src/Main.as -output ./bin/ta-gen.swf -library-path+=./lib"

TMPFILE=./adl.tmp

adl 2> /dev/null > $TMPFILE
VERSION_ADL=`sed '2q;d' $TMPFILE`

VERSION_ADL=`grep Version $TMPFILE | cut -c8-12`
CMD_RES=`rm -f $TMPFILE`

if [ !$VERSION_ADL ]; then
	echo "ERROR: cannot find ADL or obtain it's version"
	exit;
else
	echo found ADL version: $VERSION_ADL
	CMD_RES=`writedesc.sh $VERSION_ADL $VERSION_TAGEN`
	echo $CMD_RES
fi

echo building...
CMD_RES=`$BUILD_COMMAND`
