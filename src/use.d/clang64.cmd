@echo off
if not exist "%C64_HOME%\clang64\bin\clang.exe" (
    echo c64: clang64 is not installed.
    exit /b 1
)
set "C64_TOOLCHAIN=clang64"
set "C64_TARGET=x86_64-w64-windows-gnu"
set "C64_TOOLCHAIN_HOME=%C64_HOME%\clang64"
set "C64_GCC_HOME="
set "C64_CCACHE="
set "PATH=%C64_HOME%\bin;%C64_TOOLCHAIN_HOME%\bin;%C64_BASE_PATH%"
echo c64: using clang64.
