# Building projects

[中文](building-projects_zh.md)

Select the toolchain included with the distribution before using a compiler: `use mingw64` in `c64.zip`, or `use mingw32` in `c64-i686.zip`. Selection is local to the current CMD or shell session.

## Compile directly with GCC

A practical debug build is:

    gcc -g3 -O0 -Wall -Wextra main.c -o app.exe

A compact release build is:

    gcc -O2 -Wall -Wextra main.c -o app.exe

Use `g++` for C++ sources and linking C++ programs. Add libraries after source or object files, for example `-lws2_32` for Winsock.

## Make

A minimal `Makefile` can use the selected compiler directly:

```make
CC = gcc
CFLAGS = -Wall -Wextra -O2

app.exe: main.c
	$(CC) $(CFLAGS) $< -o $@
```

Build it with:

    make

BusyBox supplies the usual Unix command-line utilities, so conventional Makefile recipes generally work without a separate MSYS environment.

## CMake and Ninja

For a project containing `CMakeLists.txt`, generate and build out of tree:

    cmake -S . -B build -G Ninja
    cmake --build build

For a debug configuration:

    cmake -S . -B build-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug
    cmake --build build-debug

Run the generated executable from its build directory. CMake inherits the active `PATH`, so choose the target toolchain before configuration. Use a separate build directory when changing targets or build types.

## Enable compiler caching

After selecting a target, enable ccache for the session:

    use mingw64
    use ccache

c64 places compiler wrappers ahead of the toolchain binaries, so ordinary `gcc` and `g++` invocations are cached transparently. Run `use status` to confirm the cache is enabled. Select the target again or run `use reset` to disable it.

## Install third-party libraries

The main README describes three supported approaches: install under the target sysroot, set `CPATH` and `LIBRARY_PATH`, or use `PKG_CONFIG_PATH` with `pkg-config`. See [Library installation](../README.md#library-installation) for the details.
