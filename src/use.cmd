@echo off
rem Dispatch c64 session extensions from etc\use.d.

if not defined C64_HOME (
    for %%I in ("%~dp0..") do set "C64_HOME=%%~fI"
)
if not defined C64_BASE_PATH set "C64_BASE_PATH=%PATH%"

if "%~1"=="" goto :help
if /i "%~1"=="help" goto :help

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

:help
echo Usage: use ^<component^> [arguments]
echo.
echo Components are provided by %%C64_HOME%%\etc\use.d\.
echo Run "use list" to show installed components.
exit /b 0
