@echo off
setlocal EnableDelayedExpansion

set VERSION_FILE=.\VERSION
if not exist %VERSION_FILE% goto error_versio_file
set /p VERSION_TAGEN=<%VERSION_FILE%
echo found VERSION file: %VERSION_TAGEN%

set BUILD_COMMAND=%AIR_SDK_BIN%mxmlc +configname=air ./src/Main.as -output ./bin/ta-gen.swf -library-path+=./lib %*

:: extract the ADL version from the command line
set VERSION_ADL=
set TMPFILE=.\adl.tmp
set /a c=0

%AIR_SDK_BIN%adl 2> NUL > !TMPFILE!
for /f "tokens=*" %%a in (%TMPFILE%) do (
	if !c! equ 1 (
		set VERSION_ADL=%%a & goto found_adl_version
	)
	set /a c=c+1
)
goto error_adl

:found_adl_version
set VERSION_ADL=%VERSION_ADL:~8,4%
echo found ADL version: %VERSION_ADL%
cmd /c writedesc %VERSION_ADL% %VERSION_TAGEN%

echo building...
cmd /c %BUILD_COMMAND% > NUL

goto end

:error_adl
echo ERROR: cannot find ADL or obtain it's version
goto end

:error_version_file
echo ERROR: cannot find version file
goto end

:end
del /q %TMPFILE%
set TMPFILE=
set VERSION_ADL=
set VERSION_TAGEN=
