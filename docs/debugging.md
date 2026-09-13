# Debugging

[中文](debugging_zh.md)

## Build for a debugger

Compile with debug information and modest optimization while investigating a problem:

    gcc -g3 -O0 -Wall -Wextra main.c -o app.exe

Then start GDB:

    gdb app.exe

Useful first commands are:

    (gdb) break main
    (gdb) run
    (gdb) next
    (gdb) print variable_name
    (gdb) backtrace
    (gdb) quit

Use `step` to enter function calls and `continue` to resume execution. GDB's TUI can be enabled with `layout src` or `layout split`.

## Catch undefined behavior

AddressSanitizer and ThreadSanitizer are not available for MinGW-w64, but Undefined Behavior Sanitizer works with GDB. Build with:

    gcc -g3 -O1 -fsanitize=undefined -fsanitize-trap main.c -o app.exe

When undefined behavior is detected, the trap makes GDB stop at the offending instruction. Inspect the call stack with `backtrace`.

## Break an already-debugged process

c64 includes `debugbreak`. It asks Windows to break all processes currently being debugged, similar to the Windows F12 debugger hotkey. It is especially useful when a console program is waiting or stuck and its GDB window is not focused.

Run it from another c64 CMD or shell session:

    debugbreak

## Inspect symbols in external binaries

Use `c++filt` to demangle GCC-style C++ symbols. `vc++filt` performs the same job for Visual C++ decorations. `peports` prints PE import and export tables; pipe it through either filter when examining C++ DLLs.
