if [ -z "${C64_TOOLCHAIN_HOME-}" ]; then
	echo 'c64: select a target toolchain before enabling ccache.' >&2
	return 1
fi
if [ ! -x "$C64_TOOLCHAIN_HOME/bin/ccache.exe" ]; then
	echo "c64: ccache is not installed for $C64_TOOLCHAIN." >&2
	return 1
fi
export C64_CCACHE=1
export PATH="$C64_HOME/bin;$C64_TOOLCHAIN_HOME/lib/ccache;$C64_TOOLCHAIN_HOME/bin;$C64_BASE_PATH"
echo "c64: ccache enabled for $C64_TOOLCHAIN."
