# 构建项目

[English](building-projects.md)

使用编译器前，请先选择发行包包含的工具链：`c64.zip` 中使用 `use mingw64`，`c64-i686.zip` 中使用 `use mingw32`。选择仅对当前 CMD 或 shell 会话有效。

## 直接使用 GCC 编译

实用的调试构建：

    gcc -g3 -O0 -Wall -Wextra main.c -o app.exe

紧凑的发布构建：

    gcc -O2 -Wall -Wextra main.c -o app.exe

C++ 源码和 C++ 程序的链接应使用 `g++`。请将库参数置于源文件或目标文件之后，例如 Winsock 需要 `-lws2_32`。

## Make

一个最小 `Makefile` 可直接使用当前选中的编译器：

```make
CC = gcc
CFLAGS = -Wall -Wextra -O2

app.exe: main.c
	$(CC) $(CFLAGS) $< -o $@
```

构建：

    make

BusyBox 提供常见的 Unix 命令行实用程序，因此常规 Makefile 配方通常无需额外的 MSYS 环境即可运行。

## CMake 和 Ninja

对于含有 `CMakeLists.txt` 的项目，建议在源目录之外生成构建文件：

    cmake -S . -B build -G Ninja
    cmake --build build

调试配置：

    cmake -S . -B build-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug
    cmake --build build-debug

从构建目录运行生成的程序。CMake 会继承当前 `PATH`，因此配置前应先选择目标工具链。切换目标或构建类型时，请使用独立的构建目录。

## 启用编译缓存

选择目标后，可为当前会话启用 ccache：

    use mingw64
    use ccache

c64 会将编译器包装程序置于工具链二进制文件之前，因此普通的 `gcc` 和 `g++` 调用会被透明缓存。使用 `use status` 确认缓存是否启用。再次选择目标或运行 `use reset` 可关闭缓存。

## 安装第三方库

根 README 说明了三种支持方式：安装到目标 sysroot、设置 `CPATH` 和 `LIBRARY_PATH`，或者配合 `pkg-config` 使用 `PKG_CONFIG_PATH`。详细说明见 [库安装](../README.md#library-installation)。
