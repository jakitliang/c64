# 目录结构

[English](directory-layout.md)

c64 发行包是自包含的。请将其解压为一个目录，并保持相对目录结构不变。

```text
c64/
├── bin/                 基础命令与 BusyBox 实用程序
├── c64.exe              独立的 BusyBox 登录 shell 启动器
├── c64.ini              可选的启动器设置
├── c64_shell.cmd        CMD + Clink 启动器
├── etc/                 用户可编辑配置
│   ├── default/         活动文件缺失时用于恢复的出厂模板
│   ├── profile          BusyBox 登录 shell 启动文件
│   ├── profile.cmd      CMD 启动文件及 `use` 命令实现
│   ├── profile.d/       可选的用户启动片段
│   └── use.d/           会话组件脚本
├── lib/                 c64 内部脚本与支持文件
├── mingw64/             64 位 MinGW-w64 工具链及其 sysroot
└── opt/                 可选应用、集成与用户扩展
    ├── clink/           Clink 可执行文件与支持文件
    ├── clink-completions/
    └── vim/             Vim 及其运行时
```

## 启动文件

常规 CMD + Clink 体验应使用 `c64_shell.cmd`。它会初始化可编辑的 `etc/` 配置、提供基础工具，并定义 `use` 命令。

若需要小巧、独立的 BusyBox `sh -l` 登录 shell，则使用 `c64.exe`。它会设置 c64 的基本环境变量，但刻意不运行 CMD 启动脚本。

## 可定制的目录

配置修改应放在 `etc/`，不要修改 `bin/`、`lib/` 或 `mingw64/`。这些目录都是发行包文件，升级时可能被替换。

`opt/` 中包含 c64 的可选应用和集成，例如 Clink 与 Vim；它也是存放独立用户工具的预期位置。例如，可将便携式工具解压到 `opt/ollama/`，再通过 `etc/profile.d/` 启动脚本将该目录加入 `PATH`。升级时若需替换整个 c64 安装目录，请先备份个人的 `opt/` 子目录。

`etc/default/` 保存提供的出厂配置。若 `etc/` 中的活动配置损坏，删除它后再次启动 `c64_shell.cmd`，即可根据模板重新创建。

## 工具链目录

`mingw64/` 中，编译器程序位于 `mingw64/bin/`，目标 sysroot 位于 `mingw64/x86_64-w64-mingw32/`。请在会话中使用 `use mingw64` 选择它，不要将它永久加入系统 PATH。详见 [`use` 命令](use-command_zh.md)。

发行包还可能包含其他目标目录，例如 `mingw32/`；是否存在取决于构建的变体。

## 升级说明

尽量将项目源码、构建目录和个人库放在 c64 目录之外。这样替换为新版本的 c64 发行包会很简单。若必须将库安装在目标 sysroot 中，请在升级 c64 后重新安装它们。
