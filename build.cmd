@echo off
setlocal EnableDelayedExpansion

::
:: version to be written to the descriptor XML
::
set VERSION_TAGEN=1.3
::

:: extract the ADL version from the command line
set VERSION_ADL=
set TMPFILE=.\adl.tmp
set /a c=0

adl 2> nul > !TMPFILE!
for /f "tokens=*" %%a in (%TMPFILE%) do (
	if !c! equ 1 (
		set VERSION_ADL=%%a & goto found_version
	)
	set /a c=c+1
)
goto error

:found_version
set VERSION_ADL=%VERSION_ADL:~8,4%
echo found ADL version: %VERSION_ADL%
cmd /c writedesc %VERSION_ADL% %VERSION_TAGEN%
echo building...
cmd /c mxmlc +configname=air ./src/Main.as -output ./bin/ta-gen.swf -library-path+=./lib

goto end

:error
echo ERROR: cannot find ADL or obtain it's version

:end
del /q %TMPFILE%
set TMPFILE=
set VERSION_ADL=
set VERSION_TAGEN=
