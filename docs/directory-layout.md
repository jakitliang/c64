# Directory layout

[中文](directory-layout_zh.md)

A c64 distribution is self-contained. Unpack it as one directory and keep its relative layout intact.

```text
c64/
├── bin/                 Base commands and BusyBox utilities
├── c64.exe              Standalone BusyBox login-shell launcher
├── c64.ini              Optional launcher settings
├── c64_shell.cmd        CMD + Clink launcher
├── etc/                 User-editable configuration
│   ├── default/         Factory templates restored when active files are missing
│   ├── profile          BusyBox login-shell startup file
│   ├── profile.cmd      CMD startup file and `use` command implementation
│   ├── profile.d/       Optional per-user startup fragments
│   └── use.d/           Session component scripts
├── lib/                 c64's internal scripts and support files
├── mingw64/             64-bit MinGW-w64 toolchain and its sysroot
└── opt/                 Optional applications, integrations, and user extensions
    ├── clink/           Clink executable and support files
    ├── clink-completions/
    └── vim/             Vim and its runtime
```

## Files to start

Use `c64_shell.cmd` for the regular CMD + Clink experience. It initializes the editable `etc/` configuration, makes the base tools available, and provides the `use` command.

Use `c64.exe` when a small, self-contained BusyBox `sh -l` login shell is preferred. It sets basic c64 environment variables but intentionally does not run CMD startup scripts.

## Directories to customize

Make configuration changes in `etc/`, not in `bin/`, `lib/`, or `mingw64/`. Those directories are distribution files and may be replaced by an upgrade.

`opt/` contains c64's optional applications and integrations, such as Clink and Vim, and is also the intended place for self-contained user tools. For example, unpack a portable tool under `opt/ollama/` and add its directory to `PATH` through an `etc/profile.d/` startup script. Keep a backup of personal `opt/` subdirectories before replacing a c64 installation during an upgrade.

`etc/default/` is the factory copy of the supplied configuration. If an active configuration file in `etc/` becomes unusable, delete it and start `c64_shell.cmd` again to recreate it from its template.

## Toolchain directory

`mingw64/` contains the compiler programs in `mingw64/bin/` and the target sysroot under `mingw64/x86_64-w64-mingw32/`. Select it for a session with `use mingw64`; do not add it permanently to the system PATH. See [The `use` command](use-command.md).

A distribution can include other target directories, such as `mingw32/`. Their presence depends on the variant that was built.

## Upgrade note

Keep project source code, build directories, and personal libraries outside the c64 directory where possible. This makes replacing c64 with a newer unpacked distribution simple. If libraries must live in a target sysroot, reinstall them after upgrading c64.
