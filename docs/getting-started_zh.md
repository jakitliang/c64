# 快速开始

[English](getting-started.md)

## 1. 解压并启动

将 c64 `.zip` 解压到当前用户可写的任意位置。无需安装、管理员权限、注册表修改或修改系统级 `PATH`。

若要使用集成的 CMD + Clink 环境，请在 c64 安装根目录运行：

    c64_shell.cmd /unicode

`/unicode` 为可选参数；它会在 c64 初始化前把 CMD 切换为 UTF-8 代码页。

也可以运行 `c64.exe` 来启动独立的 BusyBox 登录 shell。它不会加载 CMD 启动脚本；因此，需要 CMD 别名、Clink 集成及 `use` 命令时，应优先使用 `c64_shell.cmd`。

## 2. 选择目标工具链

新的 CMD 会话默认没有选中编译目标，调用 GCC 前请先选择：

    use mingw64

这会选择 `x86_64-w64-mingw32`，通常用于构建 64 位 Windows 程序。独立的 `c64-i686.zip` 发行包提供 32 位工具链；解压该发行包后，请使用：

    use mingw32

i686 发行包是面向 Windows XP 的兼容版本，默认使用 Windows XP API 基线和
Pentium 4 CPU 架构。需要让编译器本身或构建产物运行在 32 位 Windows XP 时，
请使用它。该基线不会让较新的 API 或第三方库自动兼容 XP；若 XP 是支持目标，
请在 XP 上测试最终程序。

该选择仅影响当前会话的 `PATH`。可用下列命令查看当前状态：

    use status

使用 `use list` 列出可用会话助手；使用 `use reset` 返回基础环境。

## 3. 编译第一个程序

创建 `hello.c`：

```c
#include <stdio.h>

int main(void)
{
    puts("Hello, c64!");
}
```

编译并运行：

    gcc -Wall -Wextra -O2 hello.c -o hello.exe
    hello.exe

C++ 请使用 `g++` 及 `.cpp` 源文件。所选工具链提供 pthreads、C++11 线程和 OpenMP。

## 4. 需要时使用 Unix shell

CMD 会话中包含 BusyBox 实用程序。以下命令可启动登录 shell：

    sh -l

该 shell 会继承已选择的工具链和环境。使用 `exit` 返回 CMD。

## 下一步

* 使用 [构建项目](building-projects_zh.md) 学习 Make、CMake 和 Ninja。
* 使用 [调试](debugging_zh.md) 学习 GDB 与 UBSan。
* 使用 [配置](configuration_zh.md) 保存个人偏好。
