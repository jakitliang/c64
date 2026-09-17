@echo off
echo Installed c64 components:
for %%F in ("%C64_HOME%\etc\use.d\*.cmd") do echo   %%~nF
