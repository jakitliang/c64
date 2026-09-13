# Personalization

[中文](personalization_zh.md)

c64 is designed to be usable unchanged, but its behavior can be personalized without altering distribution files. Keep changes under `etc/` or beside `c64.exe` so they are visible, recoverable, and separate from toolchain files.

## Configure a portable home

Create or edit `c64.ini` beside `c64.exe`:

```ini
[c64]
home=home
title=My portable C environment
```

A relative `home` path is resolved relative to the c64 directory. This lets an external drive contain c64, its shell home directory, and all personal settings together. Environment variables may also be used in the value, for example `home=%USERPROFILE%\c64-home`.

## Add CMD aliases

Add aliases to `etc/aliases.cmd`. For example:

```bat
ll=dir /a $*
clean=del /q *.o *.exe 2>nul
```

Restart `c64_shell.cmd` after changing this file. Use aliases for concise interactive commands, not for build scripts: scripts should spell out their dependencies and commands.

## Adjust the prompt

Edit `etc/c64_prompt_config.lua` to adjust Clink's prompt. The supplied settings control the path display, home symbol, prompt symbol, user/host display, layout, and ANSI colors.

For example, a short single-line prompt with `~` for the home directory:

```lua
prompt_type = "folder"
prompt_useHomeSymbol = true
prompt_homeSymbol = "~"
prompt_lambSymbol = ">"
prompt_singleLine = true
```

If an edit makes the prompt unusable, delete `etc/c64_prompt_config.lua`; the next `c64_shell.cmd` startup restores it from `etc/default/`.

## Run startup fragments

Create `etc/profile.d/` for small, independent startup customizations:

* Put `.cmd` or `.bat` files there for CMD + Clink sessions.
* Put `.sh` files there for BusyBox login-shell sessions.

For example, `etc/profile.d/projects.cmd` can define an environment variable shared by project batch files:

```bat
@echo off
set "PROJECTS=C:\Users\you\Projects"
```

Use `etc/profile.cmd` and `etc/profile` for changes that belong to the complete CMD or shell startup sequence. See [Configuration](configuration.md) for the full loading model.

## Add a portable application: Ollama example

`opt/` is available for self-contained applications you want to carry with c64. The supplied Ollama archive contains `ollama.exe` and its adjacent `lib/` directory, so keep both together when unpacking it. Extract the archive into `opt/ollama/` until this path exists:

```text
opt/
└── ollama/
	├── ollama.exe
	└── lib/
```

Create `etc/profile.d/ollama.cmd` with the following contents:

```bat
@echo off
set "PATH=%C64_HOME%\opt\ollama;%PATH%"
```

Start a new `c64_shell.cmd` session, then verify the integration:

	ollama --version

The script is called after c64 initializes its base PATH, so the `ollama` command is available in every c64 CMD session while the existing c64 and selected-toolchain commands remain available.

For the BusyBox login shell, create `etc/profile.d/ollama.sh` as well:

```sh
export PATH="$C64_HOME/opt/ollama:$PATH"
```

Run `sh -l` or start `c64.exe` again after creating it. Do not use `setlocal` in the `.cmd` file: it would discard the PATH update when the startup script returns.

## Preserve a clean base environment

Use `use` components for optional SDKs, compiler targets, and other session modes; do not hard-code them in startup files. See [The `use` command](use-command.md). This keeps an ordinary c64 session predictable and makes changes easy to enable, inspect with `use status`, and reset.
