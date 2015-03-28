@echo off

if "%1"=="callback" (
	if "%VERSION_ADL%"=="" echo ERROR: VERSION_ADL is not set! & exit /b 1
	if "%VERSION_TAGEN%"=="" echo ERROR: VERSION_TAGEN is not set! & exit /b 1

	echo creating release ta-gen_v%VERSION_TAGEN%_air%VERSION_ADL%.zip...
	7za a .\release\ta-gen_v%VERSION_TAGEN%_air%VERSION_ADL%.zip .\bin\* > NUL
) else (
	build.cmd && buildrelease.cmd callback
)
