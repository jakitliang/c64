@echo off
if not defined C64_GCC_HOME (
    echo c64: select mingw64 or mingw32 before enabling ccache.
    exit /b 1
)
if not exist "%C64_GCC_HOME%\bin\ccache.exe" (
    echo c64: ccache is not installed for %C64_TOOLCHAIN%.
    exit /b 1
)
set "C64_CCACHE=1"
set "PATH=%C64_HOME%\bin;%C64_GCC_HOME%\lib\ccache;%C64_GCC_HOME%\bin;%C64_BASE_PATH%"
echo c64: ccache enabled for %C64_TOOLCHAIN%.
