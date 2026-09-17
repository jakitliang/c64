@echo off
if not defined C64_TOOLCHAIN_HOME (
    echo c64: select a target toolchain before enabling ccache.
    exit /b 1
)
if not exist "%C64_TOOLCHAIN_HOME%\bin\ccache.exe" (
    echo c64: ccache is not installed for %C64_TOOLCHAIN%.
    exit /b 1
)
set "C64_CCACHE=1"
set "PATH=%C64_HOME%\bin;%C64_TOOLCHAIN_HOME%\lib\ccache;%C64_TOOLCHAIN_HOME%\bin;%C64_BASE_PATH%"
echo c64: ccache enabled for %C64_TOOLCHAIN%.
