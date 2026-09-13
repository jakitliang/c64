# 调试

[English](debugging.md)

## 为调试器构建程序

排查问题时，应使用调试信息和较低优化级别：

    gcc -g3 -O0 -Wall -Wextra main.c -o app.exe

然后启动 GDB：

    gdb app.exe

可先使用以下命令：

    (gdb) break main
    (gdb) run
    (gdb) next
    (gdb) print variable_name
    (gdb) backtrace
    (gdb) quit

`step` 会进入函数调用，`continue` 会继续执行。可使用 `layout src` 或 `layout split` 启用 GDB 的 TUI。

## 捕获未定义行为

MinGW-w64 尚不支持 AddressSanitizer 和 ThreadSanitizer，但 Undefined Behavior Sanitizer 可以与 GDB 配合。构建命令：

    gcc -g3 -O1 -fsanitize=undefined -fsanitize-trap main.c -o app.exe

发现未定义行为后，trap 会让 GDB 停在对应指令处。使用 `backtrace` 检查调用栈。

## 中断已被调试的进程

c64 提供 `debugbreak`。它会要求 Windows 中断当前所有正被调试的进程，类似 Windows 的 F12 调试热键。当控制台程序正在等待、卡住或 GDB 窗口未聚焦时尤其有用。

从另一个 c64 CMD 或 shell 会话执行：

    debugbreak

## 查看外部二进制文件的符号

使用 `c++filt` 反修饰 GCC 风格的 C++ 符号；`vc++filt` 则处理 Visual C++ 修饰名。`peports` 可打印 PE 导入和导出表；检查 C++ DLL 时可将其输出通过任一种过滤器处理。
