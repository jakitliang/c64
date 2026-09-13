@echo off
rem Optional c64 session customizations. This file is preserved by users when needed.

if /i "%~1"==":use" goto :use

rem DOSKEY expands this in the current CMD process, so component scripts can
rem update its environment just like the use() shell function in etc\profile.
doskey use=call "%~f0" :use $*

if not exist "%C64_HOME%\etc\profile.d" exit /b 0
for %%F in ("%C64_HOME%\etc\profile.d\*.cmd" "%C64_HOME%\etc\profile.d\*.bat") do (
	if exist "%%~fF" call "%%~fF"
)
exit /b 0

:use
shift
if "%~1"=="" goto :use_help
if /i "%~1"=="help" goto :use_help
if /i "%~1"=="list" goto :use_list

set "C64_USE_NAME=%~1"
shift
set "C64_USE_SCRIPT=%C64_HOME%\etc\use.d\%C64_USE_NAME%.cmd"
if not exist "%C64_USE_SCRIPT%" (
	echo c64: unknown component "%C64_USE_NAME%"
	echo Run "use list" to show installed components.
	exit /b 1
)
call "%C64_USE_SCRIPT%" %*
exit /b %ERRORLEVEL%

:use_list
echo Installed c64 components:
for %%F in ("%C64_HOME%\etc\use.d\*.cmd") do echo   %%~nF
exit /b 0

:use_help
echo Usage: use ^<component^> [arguments]
echo.
echo Components are provided by %%C64_HOME%%\etc\use.d\.
echo Run "use list" to show installed components.
exit /b 0
