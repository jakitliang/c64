# `use` 命令

[English](use-command.md)

`use` 用于配置当前 c64 会话。启动 `c64_shell.cmd` 后可使用它，BusyBox 登录 shell 中也会定义它。由于选择组件会修改当前进程的环境，它必须是 CMD 宏或 shell 函数，而不能是普通外部程序。

## 查找组件

    use help
    use list
    use status

`use list` 显示当前发行包提供的组件。`use status` 显示 `C64_HOME`、当前选择的工具链及目标，以及 ccache 是否启用。

## 选择工具链

每次只使用一个目标：

    use mingw64

这会选择 `x86_64-w64-mingw32` 工具链，并将其 `bin/` 目录置于 `PATH` 前方。若发行包包含 32 位变体，可选择：

    use mingw32

选择目标会禁用 ccache，因此应先选择目标，再按需启用缓存：

    use mingw64
    use ccache

要取消目标选择并回到只包含 c64 基础命令的环境：

    use reset

## `use.d` 中的组件脚本

这些命令由 `etc/use.d/` 中的脚本实现：

| 环境 | 脚本形式 |
| --- | --- |
| CMD + Clink | `etc/use.d/<name>.cmd` |
| BusyBox shell | `etc/use.d/<name>.sh` |

`use <name>` 会调用 CMD 脚本，或 source shell 脚本。source 很关键：对 `PATH`、`C64_TOOLCHAIN`、`C64_TARGET`、`C64_GCC_HOME` 和 `C64_CCACHE` 的修改才能保留在当前 shell 中。

通常提供的组件包括 `mingw64`、已安装时的 `mingw32`、`ccache`、`reset`、`status` 和 `list`。

## 添加个人组件

可在 `etc/use.d/` 中创建相互对应的 `.cmd` 与 `.sh` 文件，以提供自己的会话切换命令。例如，名为 `sdk.cmd` 的 CMD 组件可设置 SDK 位置并将其工具目录放到前方：

```bat
@echo off
set "MY_SDK=C:\SDKs\example"
set "PATH=%MY_SDK%\bin;%PATH%"
echo c64: example SDK enabled.
```

将其保存为 `etc/use.d/sdk.cmd` 后，启动新的 c64 CMD 会话并运行：

    use sdk

如需对应的 BusyBox shell 组件，请创建 `etc/use.d/sdk.sh`：

```sh
export MY_SDK='C:/SDKs/example'
export PATH="$MY_SDK/bin:$PATH"
echo 'c64: example SDK enabled.'
```

除非刻意维护自定义 c64 发行版，否则应避免修改提供的目标脚本。个人脚本放在 `etc/use.d/` 中，可与核心工具链选择逻辑保持分离。
