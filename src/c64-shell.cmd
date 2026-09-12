@echo off
rem User-facing CMD launcher, analogous to MSYS2's msys2_shell.cmd.

"%ComSpec%" /d /k ""%~dp0lib\c64\init.cmd" %*"