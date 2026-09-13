# 个性化

[English](personalization.md)

c64 无需修改即可使用，但可以在不改动发行包文件的前提下个性化。请将修改保留在 `etc/` 或 `c64.exe` 旁边，以便查看、恢复，并与工具链文件分离。

## 配置便携式主目录

在 `c64.exe` 旁创建或编辑 `c64.ini`：

```ini
[c64]
home=home
title=My portable C environment
```

相对 `home` 路径以 c64 目录为基准解析。这样可移动磁盘中可同时保存 c64、其 shell 主目录以及全部个人设置。值中也可使用环境变量，例如 `home=%USERPROFILE%\c64-home`。

## 添加 CMD 别名

将别名添加至 `etc/aliases.cmd`。例如：

```bat
ll=dir /a $*
clean=del /q *.o *.exe 2>nul
```

修改后请重新启动 `c64_shell.cmd`。别名适合简化交互式命令；构建脚本不应依赖别名，而应明确写出依赖和命令。

## 调整提示符

编辑 `etc/c64_prompt_config.lua` 可调整 Clink 提示符。提供的设置控制路径显示、主目录符号、提示符符号、用户/主机显示、布局和 ANSI 颜色。

例如，使用 `~` 表示主目录的短单行提示符：

```lua
prompt_type = "folder"
prompt_useHomeSymbol = true
prompt_homeSymbol = "~"
prompt_lambSymbol = ">"
prompt_singleLine = true
```

若修改使提示符无法使用，删除 `etc/c64_prompt_config.lua`；下次启动 `c64_shell.cmd` 会从 `etc/default/` 恢复默认配置。

## 运行启动片段

可创建 `etc/profile.d/` 存放小型、独立的启动定制：

* CMD + Clink 会话使用 `.cmd` 或 `.bat` 文件。
* BusyBox 登录 shell 会话使用 `.sh` 文件。

例如，`etc/profile.d/projects.cmd` 可定义项目批处理脚本共用的环境变量：

```bat
@echo off
set "PROJECTS=C:\Users\you\Projects"
```

属于完整 CMD 或 shell 启动序列的修改应写入 `etc/profile.cmd` 与 `etc/profile`。完整加载模型见 [配置](configuration_zh.md)。

## 添加便携应用：Ollama 示例

`opt/` 用于存放希望随 c64 一起携带的独立应用。提供的 Ollama 压缩包包含 `ollama.exe` 及其相邻的 `lib/` 目录，因此解压时必须让两者保持在一起。请将压缩包解压到 `opt/ollama/`，使其结构如下：

```text
opt/
└── ollama/
	├── ollama.exe
	└── lib/
```

创建 `etc/profile.d/ollama.cmd`，内容如下：

```bat
@echo off
set "PATH=%C64_HOME%\opt\ollama;%PATH%"
```

重新启动一个 `c64_shell.cmd` 会话，然后验证集成：

	ollama --version

该脚本会在 c64 初始化基础 PATH 后执行，因此每个 c64 CMD 会话都可使用 `ollama` 命令，同时原有 c64 命令和已选择工具链的命令仍然可用。

对于 BusyBox 登录 shell，还应创建 `etc/profile.d/ollama.sh`：

```sh
export PATH="$C64_HOME/opt/ollama:$PATH"
```

创建后运行 `sh -l`，或重新启动 `c64.exe`。`.cmd` 文件中不要使用 `setlocal`，否则启动脚本返回时会丢弃对 PATH 的修改。

## 保持基础环境干净

可选 SDK、编译目标和其他会话模式应使用 `use` 组件，而不是写死在启动文件中。详见 [`use` 命令](use-command_zh.md)。这样普通 c64 会话保持可预测，变更也易于启用、通过 `use status` 检查以及重置。
