@echo off
rem Internal c64 CMD session initialization.

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
if not exist "%C64_HOME%\etc\default" mkdir "%C64_HOME%\etc\default"
if not exist "%C64_HOME%\etc\aliases.cmd" copy /y "%C64_HOME%\etc\default\aliases.cmd.default" "%C64_HOME%\etc\aliases.cmd" >nul
if not exist "%C64_HOME%\etc\c64_prompt_config.lua" copy /y "%C64_HOME%\etc\default\c64_prompt_config.lua.default" "%C64_HOME%\etc\c64_prompt_config.lua" >nul
if not exist "%C64_HOME%\etc\clink_settings" copy /y "%C64_HOME%\etc\default\clink_settings.default" "%C64_HOME%\etc\clink_settings" >nul
if not exist "%C64_HOME%\etc\profile" copy /y "%C64_HOME%\etc\default\profile.default" "%C64_HOME%\etc\profile" >nul
if not exist "%C64_HOME%\etc\profile.cmd" copy /y "%C64_HOME%\etc\default\profile.cmd.default" "%C64_HOME%\etc\profile.cmd" >nul

if not defined C64_BASE_PATH set "C64_BASE_PATH=%PATH%"
set "PATH=%C64_HOME%\bin;%C64_BASE_PATH%"
set "C64_TOOLCHAIN="
set "C64_TARGET="
set "C64_GCC_HOME="
set "C64_CCACHE="
set "C64_VIM_HOME=%C64_HOME%\opt\vim"

if exist "%C64_HOME%\etc\aliases.cmd" doskey /macrofile="%C64_HOME%\etc\aliases.cmd"

if exist "%C64_HOME%\opt\clink\clink_x64.exe" (
    "%C64_HOME%\opt\clink\clink_x64.exe" inject --quiet --profile "%C64_HOME%\etc" --scripts "%C64_HOME%\lib\clink"
)

if exist "%C64_HOME%\etc\profile.cmd" call "%C64_HOME%\etc\profile.cmd"
exit /b %ERRORLEVEL%

:help
echo Usage: init.cmd [/unicode]
echo.
echo /unicode  Set the active CMD code page to UTF-8 before initializing c64.
exit /b 0
