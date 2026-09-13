# Configuration

[中文](configuration_zh.md)

## Configuration layout

The first `c64_shell.cmd` startup creates editable files in `etc/` from templates in `etc/default/`. This leaves the supplied defaults intact and makes personal changes easy to recover from.

| File | Purpose |
| --- | --- |
| `etc/aliases.cmd` | CMD aliases loaded for the c64 session |
| `etc/profile.cmd` | CMD session initialization and persistent environment changes |
| `etc/profile` | BusyBox login-shell initialization |
| `etc/c64_prompt_config.lua` | Clink prompt appearance |
| `etc/clink_settings` | Clink settings |

Delete an active configuration file to recreate it from its corresponding `etc/default/` template on the next `c64_shell.cmd` startup.

## Persist environment changes

Put CMD-specific changes in `etc/profile.cmd`. For example, add a private tools directory:

    set PATH=C:\Users\you\bin;%PATH%

Put shell-specific changes in `etc/profile`, using shell syntax instead:

    export PATH="$HOME/bin:$PATH"

To keep small scripts separate from the main profiles, create `etc/profile.d/`. Files ending in `.cmd` or `.bat` are run for CMD; `.sh` files are sourced by the login shell.

## Home directory and console title

The optional `c64.ini` next to `c64.exe` controls the standalone launcher's home directory and title. A relative home path is resolved from the c64 directory, allowing the entire environment and its home directory to live together on removable media.

```ini
[c64]
home=home
title=c64 development environment
```

## Keep target choice session-local

Do not permanently prepend `mingw64/bin` or `mingw32/bin` to a global PATH. Start c64 and select a target with `use mingw64` or `use mingw32` per session. This avoids accidental compiler selection and lets one installation support both targets cleanly.
