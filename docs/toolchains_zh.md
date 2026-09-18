# 工具链

[English](toolchains.md)

c64 提供三套相互独立的 Windows 工具链。使用 `use` 为当前 CMD 或登录 shell 会话选择工具链；该操作只改变当前会话的 `PATH` 和工具链变量。

| 工具链 | 发行包 | 编译器命令 | 目标与运行时 | 适用场景 |
| --- | --- | --- | --- | --- |
| `mingw64` | `c64.zip` | `gcc`、`g++` | x86_64 MinGW-w64、MSVCRT | 通用 64 位 Windows C/C++ 开发，以及既有的 c64 GCC 项目 |
| `mingw32` | `c64-i686.zip` | `gcc`、`g++` | i686 MinGW-w64、MSVCRT、Windows XP API 基线 | 32 位 Windows 和 Windows XP 兼容性 |
| `clang64` | `c64-clang64.zip` | `clang`、`clang++` | x86_64 MinGW-w64、UCRT | 基于 Clang、LLD、LLVM 工具、CMake 与 IDE 的现代 64 位 Windows 开发 |

每个发行包均可独立使用。可将 `c64-i686.zip` 中的 `c64/mingw32/` 合并到已解压的 `c64.zip`，以加入 `mingw32`。`clang64` 应保持独立安装：它有自己的 sysroot 与运行时。

## 按场景选择

开始一个常规的 64 位 Windows 程序、维护 GCC/MinGW 项目，或希望使用默认 c64 工作流时，选择 `mingw64`。只有需要 32 位可执行文件时才选择 `mingw32`，尤其是 Windows XP 仍在支持范围内时。项目、IDE 或团队规范要求使用 Clang，或者希望在现代 64 位 Windows 项目中使用 Clang 诊断与 LLVM 工具时，选择 `clang64`。

若一个项目已经可以构建，应继续使用生成其已有 object file 和 static library 的工具链。切换工具链意味着这些依赖也需要重新构建。

## 选择并查看工具链

启动 `c64_shell.cmd` 后，选择需要的环境：

    use mingw64
    use status

在同一会话中切换时，可直接选择另一套工具链，或先重置：

    use reset
    use clang64

`use list` 列出当前安装中提供的会话助手。未安装的工具链会报告不可用。

## 通用 64 位 GCC：`mingw64`

`mingw64` 是 `c64.zip` 的默认工具链，适用于以下常见场景：

* 原生 Windows 命令行工具、GUI 程序或只需运行在受支持 64 位 Windows 上的实用程序。
* 已围绕 `gcc`、`g++` 和 GNU 风格选项构建的 Makefile、CMake 项目或第三方依赖。
* 使用静态依赖，并希望采用标准 c64 GCC 工作流的项目。

例如，构建一个常规程序：

    use mingw64
    gcc -Wall -Wextra -O2 main.c -o app.exe
    g++ -std=c++23 -O2 main.cpp -o app.exe

除非兼容性需求要求 `mingw32`，或者项目明确受益于 Clang，否则应优先将它作为默认选择。

## 32 位与 Windows XP GCC：`mingw32`

安装 `c64-i686.zip` 并在以下场景选择 `mingw32`：

* 仍需部署到 32 位 Windows 的遗留环境。
* 程序、插件或 DLL 必须匹配 32 位宿主进程。
* 产品明确支持 32 位 Windows XP。

例如：

    use mingw32
    gcc -O2 main.c -o app.exe

该工具链默认采用 Windows XP API 基线和 Pentium 4 CPU 架构。当编译器本身或构建产物需要运行在 32 位 Windows XP 时，请使用它。这一基线不会让源码、第三方库或运行时行为自动兼容 XP；若 XP 是部署目标，请在 XP 上测试最终程序。

即使不需要 XP，32 位程序仍可使用该工具链，但不要依赖超出该基线的 API。若目标程序完全是 64 位，应改用 `mingw64`。

## 现代 Clang：`clang64`

构建或获取 `c64-clang64.zip`，将其独立解压后选择 Clang 环境。它适合以下场景：

* 偏好 Clang 诊断和 LLVM 工具的新 C++20/C++23 应用。
* 在 CLion 或其他配置为使用 Clang 的 IDE 中打开的 CMake 项目。
* 团队或依赖已使用面向 MinGW 的 Clang 工具链。
* 希望用 GCC 和 Clang 同时构建同一 64 位项目，以排查编译器特有告警或行为。

例如：

    use clang64
    clang -Wall -Wextra -O2 main.c -o app.exe
    clang++ -std=c++23 -O2 main.cpp -o app.exe

`clang64` 提供 Clang、LLD、LLVM binutils 以及基于 UCRT 的 MinGW-w64 sysroot。驱动配置已包含匹配的 GCC 支持运行时和 C++ 标准库头文件路径；正常调用 `clang` 与 `clang++` 即可，无需手动追加这些路径。

在 CMake 中，将 `CMAKE_C_COMPILER` 设置为 clang64 安装中的 `clang.exe`，并将 `CMAKE_CXX_COMPILER` 设置为其中的 `clang++.exe`；切换编译器后应使用新的构建目录。在 CLion 中，应为 clang64 配置单独的工具链和 CMake Profile，而不是复用 GCC 的构建目录。

## 运行时与库边界

`mingw64` 和 `mingw32` 使用 MSVCRT；`clang64` 使用 UCRT。不要在链接边界混用由 `clang64` 与两套 GCC 工具链构建的 object file 或 static library。应用程序及其静态依赖应使用同一套工具链重新构建。

DLL 接口也应遵守相同原则：内存、C++ 对象、异常和标准库类型应在创建它们的运行时家族内完成所有权管理。跨运行时 DLL 接口宜使用稳定的 C ABI。

第三方库应安装在所选工具链的 sysroot 下，或按[构建项目](building-projects_zh.md)所述通过 `CPATH`、`LIBRARY_PATH` 和 `PKG_CONFIG_PATH` 公开。
