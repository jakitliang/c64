@echo off
if not exist "%C64_HOME%\mingw32\bin\gcc.exe" (
    echo c64: mingw32 is not installed.
    exit /b 1
)
set "C64_TOOLCHAIN=mingw32"
set "C64_TARGET=i686-w64-mingw32"
set "C64_GCC_HOME=%C64_HOME%\mingw32"
set "C64_CCACHE="
set "PATH=%C64_HOME%\bin;%C64_GCC_HOME%\bin;%C64_BASE_PATH%"
echo c64: using mingw32.
