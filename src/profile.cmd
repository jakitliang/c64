@echo off
rem Optional c64 session customizations. This file is preserved by users when needed.

if not exist "%C64_HOME%\etc\profile.d" exit /b 0
for %%F in ("%C64_HOME%\etc\profile.d\*.cmd" "%C64_HOME%\etc\profile.d\*.bat") do (
	if exist "%%~fF" call "%%~fF"
)
