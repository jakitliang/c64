# 配置

[English](configuration.md)

## 配置布局

第一次启动 `c64_shell.cmd` 时，会从 `etc/default/` 中的模板创建 `etc/` 下可编辑的配置文件。这既保留了出厂默认值，也便于恢复个人配置。

| 文件 | 用途 |
| --- | --- |
| `etc/aliases.cmd` | c64 会话加载的 CMD 别名 |
| `etc/profile.cmd` | CMD 会话初始化及持久环境修改 |
| `etc/profile` | BusyBox 登录 shell 初始化 |
| `etc/c64_prompt_config.lua` | Clink 提示符外观 |
| `etc/clink_settings` | Clink 设置 |

删除已启用的配置文件后，下次启动 `c64_shell.cmd` 时会根据相应的 `etc/default/` 模板重新创建它。

## 保存环境修改

将仅适用于 CMD 的修改写入 `etc/profile.cmd`。例如，加入私人工具目录：

    set PATH=C:\Users\you\bin;%PATH%

将仅适用于 shell 的修改写入 `etc/profile`，并使用 shell 语法：

    export PATH="$HOME/bin:$PATH"

若要将小脚本与主 profile 分开，请创建 `etc/profile.d/`。CMD 会运行其中以 `.cmd` 或 `.bat` 结尾的文件；登录 shell 会 source 其中的 `.sh` 文件。

## 主目录与控制台标题

`c64.exe` 旁的可选 `c64.ini` 可控制独立启动器的主目录和标题。相对 `home` 路径以 c64 目录为基准解析，因此可以把整个环境及主目录放在同一份可移动介质中。

```ini
[c64]
home=home
title=c64 development environment
```

## 让目标选择保持会话级

不要将发行包中的 `mingw64/bin` 或 `mingw32/bin` 永久加入全局 PATH。每个会话启动 c64 后，再执行 `use mingw64` 或 `use mingw32` 选择已安装的目标。这样可避免误用编译器，并使每个发行包的工具链彼此隔离。
