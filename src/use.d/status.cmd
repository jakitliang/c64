@echo off
echo C64_HOME=%C64_HOME%
if defined C64_TOOLCHAIN (
    echo C64_TOOLCHAIN=%C64_TOOLCHAIN%
    echo C64_TARGET=%C64_TARGET%
    echo C64_GCC_HOME=%C64_GCC_HOME%
) else (
    echo C64_TOOLCHAIN=none
)
if defined C64_CCACHE (echo C64_CCACHE=enabled) else (echo C64_CCACHE=disabled)
