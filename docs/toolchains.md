# Toolchains

[中文](toolchains_zh.md)

c64 provides three independent Windows toolchains. Select one for the current CMD or login-shell session with `use`; this changes only that session's `PATH` and toolchain variables.

| Toolchain | Distribution | Compiler commands | Target and runtime | Best suited to |
| --- | --- | --- | --- | --- |
| `mingw64` | `c64.zip` | `gcc`, `g++` | x86_64 MinGW-w64, MSVCRT | General 64-bit Windows C/C++ development and existing c64 GCC projects |
| `mingw32` | `c64-i686.zip` | `gcc`, `g++` | i686 MinGW-w64, MSVCRT, Windows XP API baseline | 32-bit Windows and Windows XP compatibility |
| `clang64` | `c64-clang64.zip` | `clang`, `clang++` | x86_64 MinGW-w64, UCRT | Modern 64-bit Windows development with Clang, LLD, LLVM tools, CMake, and IDE integration |

Each distribution is self-contained. `mingw32` may be added to an unpacked `c64.zip` by merging its `c64/mingw32/` directory. Keep `clang64` as its own installation: it has an independent sysroot and runtime.

## Choose by scenario

Choose `mingw64` when you are starting a conventional 64-bit Windows program, maintaining a GCC/MinGW project, or want the default c64 workflow. Choose `mingw32` only when you need a 32-bit executable, especially when Windows XP is a supported target. Choose `clang64` when a project, IDE, or team standard uses Clang, or when you want Clang diagnostics and LLVM tooling for a modern 64-bit Windows project.

If a project already builds successfully, keep using the toolchain that built its existing object files and static libraries. Changing toolchains means rebuilding those dependencies too.

## Select and inspect a toolchain

Start `c64_shell.cmd`, then select the desired environment:

    use mingw64
    use status

To change toolchains, select another one in the same session or reset first:

    use reset
    use clang64

`use list` shows the helpers included by the current installation. An unavailable toolchain reports that it is not installed.

## General 64-bit GCC: `mingw64`

`mingw64` is the default toolchain in `c64.zip`. It is the practical starting point for these common cases:

* A native Windows command-line tool, GUI program, or utility that only needs to run on supported 64-bit Windows versions.
* An existing Makefile, CMake project, or third-party dependency built around `gcc`, `g++`, and GNU-style options.
* A project that packages static dependencies and needs the normal c64 GCC workflow.

For example, select it to build an ordinary application:

    use mingw64
    gcc -Wall -Wextra -O2 main.c -o app.exe
    g++ -std=c++23 -O2 main.cpp -o app.exe

Use this as the default unless a compatibility requirement calls for `mingw32`, or your project specifically benefits from Clang.

## 32-bit and Windows XP GCC: `mingw32`

Install `c64-i686.zip` and select `mingw32` for these cases:

* A legacy deployment estate still running 32-bit Windows.
* A program, plugin, or DLL that must match a 32-bit host process.
* A product that explicitly supports 32-bit Windows XP.

For example:

    use mingw32
    gcc -O2 main.c -o app.exe

This toolchain defaults to a Windows XP API baseline and Pentium 4 CPU architecture. Use it when the compiler itself or the resulting program must run on 32-bit Windows XP. The baseline does not make source code, third-party libraries, or runtime behavior XP-compatible; test the completed program on XP when it is a deployment target.

For 32-bit software that does not require XP, the same toolchain remains appropriate, but avoid relying on APIs outside the configured baseline. If the target program is purely 64-bit, use `mingw64` instead.

## Modern Clang: `clang64`

Build or obtain `c64-clang64.zip`, unpack it independently, and select its Clang environment. Use it for scenarios such as:

* A new C++20/C++23 application where Clang diagnostics and LLVM tooling are preferred.
* A CMake project opened in CLion or another IDE that is configured to use Clang.
* A team or dependency set that already builds with a MinGW-targeting Clang toolchain.
* Investigating compiler-specific warnings or behavior by building the same 64-bit project with both GCC and Clang.

For example:

    use clang64
    clang -Wall -Wextra -O2 main.c -o app.exe
    clang++ -std=c++23 -O2 main.cpp -o app.exe

`clang64` supplies Clang, LLD, and LLVM binutils with a UCRT-based MinGW-w64 sysroot. Its driver configuration already supplies the matching GCC support runtime and C++ standard-library include paths; invoke `clang` and `clang++` normally rather than manually adding those paths.

For CMake, set `CMAKE_C_COMPILER` to the `clang.exe` in the clang64 installation and `CMAKE_CXX_COMPILER` to its `clang++.exe`; choose a fresh build directory after changing compilers. In CLion, configure a separate toolchain and CMake profile for clang64 rather than reusing a GCC build directory.

## Runtime and library boundaries

`mingw64` and `mingw32` use MSVCRT. `clang64` uses UCRT. Do not mix object files or static libraries built by `clang64` with ones built by either GCC toolchain across a linking boundary. Rebuild all of the application and its static dependencies with one selected toolchain.

DLL interfaces require the same care: keep ownership of allocated memory, C++ objects, exceptions, and standard-library types inside the runtime family that created them. Prefer a stable C ABI for cross-runtime DLL interfaces.

Third-party libraries should be installed under the selected toolchain's sysroot, or exposed through `CPATH`, `LIBRARY_PATH`, and `PKG_CONFIG_PATH` as described in [Building projects](building-projects.md).
