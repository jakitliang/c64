if [ ! -x "$C64_HOME/mingw64/bin/gcc.exe" ]; then
	echo 'c64: mingw64 is not installed.' >&2
	return 1
fi
export C64_TOOLCHAIN=mingw64
export C64_TARGET=x86_64-w64-mingw32
export C64_GCC_HOME="$C64_HOME/mingw64"
export C64_TOOLCHAIN_HOME="$C64_GCC_HOME"
unset C64_CCACHE
export PATH="$C64_HOME/bin;$C64_GCC_HOME/bin;$C64_BASE_PATH"
echo 'c64: using mingw64.'
