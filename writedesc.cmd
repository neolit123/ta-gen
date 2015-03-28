@echo off
setlocal EnableDelayedExpansion

set FILE=.\bin\ta-gen.xml
set VERSION_ADL=%1
if "%VERSION_ADL%"=="" echo defaulting VERSION_ADL to 17.0 & set VERSION_ADL=17.0
set VERSION_TAGEN=%2
if "%VERSION_TAGEN%"=="" echo defaulting VERSION_TAGEN to 1.0 & set VERSION_TAGEN=1.0

echo writing descriptor for ADL %VERSION_ADL%, ta-gen %VERSION_TAGEN%...

(
	echo ^<?xml version="1.0" encoding="UTF-8" standalone="no" ?^>
	echo ^<application xmlns="http://ns.adobe.com/air/application/%VERSION_ADL%"^>
	echo 	^<id^>ta-gen^</id^>
	echo 	^<versionNumber^>%VERSION_TAGEN%^</versionNumber^>
	echo 	^<filename^>ta-gen^</filename^>
	echo 	^<description/^>
	echo 	^<name^>ta-gen v%VERSION_TAGEN%^</name^>
	echo 	^<copyright/^>
	echo 	^<initialWindow^>
	echo 		^<content^>ta-gen.swf^</content^>
	echo 		^<systemChrome^>standard^</systemChrome^>
	echo 		^<transparent^>false^</transparent^>
	echo 		^<visible^>false^</visible^>
	echo 		^<fullScreen^>false^</fullScreen^>
	echo 		^<aspectRatio^>portrait^</aspectRatio^>
	echo 		^<renderMode^>auto^</renderMode^>
	echo 	^</initialWindow^>
	echo 	^<icon/^>
	echo 	^<customUpdateUI^>false^</customUpdateUI^>
	echo 	^<allowBrowserInvocation^>false^</allowBrowserInvocation^>
	echo ^</application^>
) > %FILE%

echo writing the Version.as file...

set VERSION_AS_FILE=.\src\Version.as
set DEFAULT_AS_VERSION=1.0
if exist %VERSION_AS_FILE% del /f /q %VERSION_AS_FILE%
for /f "delims=" %%a in (%VERSION_AS_FILE%.in) do (
	set OUT=%%a
	set OUT=!OUT:%DEFAULT_AS_VERSION%=%VERSION_TAGEN%!
	echo !OUT!>> %VERSION_AS_FILE%
)

set VERSION_AS_FILE=
set DEFAULT_AS_VERSION=
set FILE=
