@echo off
rem Public CMD entry point for c64. It may be used by c64.exe, Windows
rem Terminal profiles, shortcuts, or an existing cmd.exe session.

if not defined C64_HOME (
    for %%I in ("%~dp0\..\..") do set "C64_HOME=%%~fI"
)
if "%C64_HOME:~-1%"=="\" set "C64_HOME=%C64_HOME:~0,-1%"

:arguments
if "%~1"=="" goto :initialize
if /i "%~1"=="/unicode" (
    chcp 65001 >nul
    shift
    goto :arguments
)
if /i "%~1"=="/?" goto :help
if /i "%~1"=="/help" goto :help

echo c64: unknown init option "%~1"
exit /b 2

:initialize
call "%C64_HOME%\bin\init.cmd"
exit /b %ERRORLEVEL%

:help
echo Usage: init.bat [/unicode]
echo.
echo /unicode  Set the active CMD code page to UTF-8 before initializing c64.
exit /b 0
