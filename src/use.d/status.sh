echo "C64_HOME=$C64_HOME"
if [ -n "${C64_TOOLCHAIN-}" ]; then
	echo "C64_TOOLCHAIN=$C64_TOOLCHAIN"
	echo "C64_TARGET=$C64_TARGET"
	echo "C64_TOOLCHAIN_HOME=$C64_TOOLCHAIN_HOME"
	echo "C64_GCC_HOME=$C64_GCC_HOME"
else
	echo 'C64_TOOLCHAIN=none'
fi
if [ -n "${C64_CCACHE-}" ]; then
	echo 'C64_CCACHE=enabled'
else
	echo 'C64_CCACHE=disabled'
fi
