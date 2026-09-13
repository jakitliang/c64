# Getting started

[中文](getting-started_zh.md)

## 1. Unpack and start

Unpack the c64 `.zip` file anywhere writable by the current user. No installer, administrator access, registry changes, or system-wide PATH changes are required.

For the integrated CMD + Clink environment, run this from the c64 installation root:

    c64_shell.cmd /unicode

`/unicode` is optional. It switches CMD to UTF-8 before c64 initializes the session.

Alternatively, run `c64.exe` to start a self-contained BusyBox login shell. It does not load CMD startup scripts, so prefer `c64_shell.cmd` when you want the CMD aliases, Clink integration, and the `use` command.

## 2. Select a target

A new CMD session has no compiler target selected. Choose one before invoking GCC:

    use mingw64

This selects `x86_64-w64-mingw32`, the normal choice for 64-bit Windows applications. The separate `c64-i686.zip` distribution provides a 32-bit toolchain; after unpacking that distribution, use:

    use mingw32

Selection changes `PATH` only for the current session. Check the current state with:

    use status

List all available session helpers with `use list`, and return to the base environment with `use reset`.

## 3. Build a first program

Create `hello.c`:

```c
#include <stdio.h>

int main(void)
{
    puts("Hello, c64!");
}
```

Compile and run it:

    gcc -Wall -Wextra -O2 hello.c -o hello.exe
    hello.exe

For C++, use `g++` and a `.cpp` source file. The selected toolchain provides pthreads, C++11 threads, and OpenMP.

## 4. Use the Unix shell when useful

The CMD session includes BusyBox utilities. Start a login shell with:

    sh -l

The shell uses the same selected toolchain and environment. Leave it with `exit` to return to CMD.

## Next steps

* [Build projects](building-projects.md) with Make, CMake, or Ninja.
* [Debug a program](debugging.md) with GDB and UBSan.
* [Configure the environment](configuration.md) to persist your preferences.
