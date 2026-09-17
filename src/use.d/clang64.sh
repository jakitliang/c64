if [ ! -x "$C64_HOME/clang64/bin/clang.exe" ]; then
	echo 'c64: clang64 is not installed.' >&2
	return 1
fi
export C64_TOOLCHAIN=clang64
export C64_TARGET=x86_64-w64-windows-gnu
export C64_TOOLCHAIN_HOME="$C64_HOME/clang64"
unset C64_GCC_HOME C64_CCACHE
export PATH="$C64_HOME/bin;$C64_TOOLCHAIN_HOME/bin;$C64_BASE_PATH"
echo 'c64: using clang64.'
