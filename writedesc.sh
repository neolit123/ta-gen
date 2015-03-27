#!/bin/sh

FILE=./bin/ta-gen.xml
VERSION_ADL=$1
if [ -z "$VERSION_ADL" ]; then
	echo "defaulting VERSION_ADL to 17.0"
	VERSION_ADL=17.0
fi
VERSION_TAGEN=$2
if [ -z "$VERSION_TAGEN" ]; then
	echo "defaulting VERSION_TAGEN to 1.0"
	VERSION_TAGEN=1.0
fi

echo "writing descriptor for ADL $VERSION_ADL, ta-gen $VERSION_TAGEN..."

TEXT="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>
<application xmlns=\"http://ns.adobe.com/air/application/$VERSION_ADL\">
	<id>ta-gen</id>
	<versionNumber>$VERSION_TAGEN</versionNumber>
	<filename>ta-gen</filename>
	<description/>
	<name>ta-gen v$VERSION_TAGEN</name>
	<copyright/>
	<initialWindow>
		<content>ta-gen.swf</content>
		<systemChrome>standard</systemChrome>
		<transparent>false</transparent>
		<visible>false</visible>
		<fullScreen>false</fullScreen>
		<aspectRatio>portrait</aspectRatio>
		<renderMode>auto</renderMode>
	</initialWindow>
	<icon/>
	<customUpdateUI>false</customUpdateUI>
	<allowBrowserInvocation>false</allowBrowserInvocation>
</application>"

echo "$TEXT" > $FILE

echo "writing the Version.as file..."

DEFAULT_AS_VERSION="1.0"
VERSION_AS_FILE="./src/Version.as"
cp $VERSION_AS_FILE.in $VERSION_AS_FILE
sed -i.in "s/$DEFAULT_AS_VERSION/$VERSION_TAGEN/g" $VERSION_AS_FILE
