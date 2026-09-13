# The `use` command

[中文](use-command_zh.md)

`use` configures the current c64 session. It is available after starting `c64_shell.cmd`, and is also defined in the BusyBox login shell. It must be a CMD macro or shell function—not a normal external program—because selecting a component changes the current process environment.

## Discover components

    use help
    use list
    use status

`use list` shows components supplied by the current distribution. `use status` displays `C64_HOME`, the selected toolchain and target, and whether ccache is enabled.

## Select a toolchain

Use one target at a time:

    use mingw64

This selects the `x86_64-w64-mingw32` toolchain and prepends its `bin/` directory to `PATH`. A distribution containing the 32-bit variant can select it with:

    use mingw32

Selecting a target disables ccache, so select the target first and then enable the cache if needed:

    use mingw64
    use ccache

To discard the target and return to only c64's base commands:

    use reset

## Add the i686 toolchain to an x64 installation

On 64-bit Windows, one c64 installation can provide both targets. Download the
matching `c64-i686.zip` release, then extract only its `c64/mingw32/` directory
into the root of an existing `c64.zip` installation. The resulting layout is:

```text
c64/
├── mingw64/
└── mingw32/
```

Use matching releases: do not combine toolchain directories from different
c64 versions. Do not extract the entire i686 archive over the x64
installation; only merge `mingw32/`. The shared launchers, base tools, and
configuration should remain those from `c64.zip`.

Start a new c64 session and select the added target:

    use mingw32

Run `use status` to verify that `C64_TARGET` is `i686-w64-mingw32`. Standard
64-bit Windows installations can run the 32-bit compiler programs through
WoW64. This is a convenient way to make one portable c64 directory support
both 64-bit and 32-bit application builds.

## Component scripts in `use.d`

The commands are implemented by scripts in `etc/use.d/`:

| Environment | Script form |
| --- | --- |
| CMD + Clink | `etc/use.d/<name>.cmd` |
| BusyBox shell | `etc/use.d/<name>.sh` |

`use <name>` calls the CMD script or sources the shell script. Sourcing is important: updates to `PATH`, `C64_TOOLCHAIN`, `C64_TARGET`, `C64_GCC_HOME`, and `C64_CCACHE` then remain in the active shell.

The supplied components are normally `mingw64`, `mingw32` when installed, `ccache`, `reset`, `status`, and `list`.

## Add a personal component

Create matching `.cmd` and `.sh` files in `etc/use.d/` to provide your own session switch. For example, a CMD component named `sdk.cmd` may set an SDK location and prepend its tools:

```bat
@echo off
set "MY_SDK=C:\SDKs\example"
set "PATH=%MY_SDK%\bin;%PATH%"
echo c64: example SDK enabled.
```

After saving it as `etc/use.d/sdk.cmd`, start a new c64 CMD session and run:

    use sdk

For a corresponding BusyBox shell component, create `etc/use.d/sdk.sh`:

```sh
export MY_SDK='C:/SDKs/example'
export PATH="$MY_SDK/bin:$PATH"
echo 'c64: example SDK enabled.'
```

Avoid modifying the supplied target scripts unless deliberately maintaining a custom c64 distribution. Personal scripts in `etc/use.d/` stay separate from the core toolchain selection logic.
