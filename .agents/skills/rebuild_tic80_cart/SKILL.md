---
name: Rebuilding TIC-80 Cartridges from Lua
description: Instructions on how to rebuild/compile a .tic cartridge by importing a modified .lua source file.
---

To rebuild/inject a `.lua` source file into a `.tic` cartridge in TIC-80 from the command line, follow these steps:

### The Rebuild Command
Run TIC-80 in CLI mode, setting the filesystem root (`--fs=.`) to the project directory, and pass the sequential commands to `load`, `import code`, `save`, and `exit`:

```bash
/Applications/tic80.app/Contents/MacOS/tic80 --fs=. --cli --cmd="load trumpet-practice.tic & import code trumpet-practice.lua & save & exit"
```

### Why standard runs fail without it:
1. **TIC-80 CLI relative pathing**: If you do not specify `--fs=.` or `--fs=<path>`, TIC-80 resolves the `load` and `import` paths relative to its default internal document root instead of your shell's working directory, leading to `file not found` errors.
2. **Treating dots as carts**: Passing `.` as a bare argument (e.g. `tic80 .`) makes TIC-80 try to load a cartridge named `.`, resulting in a `cart not loaded` error. The `--fs=.` flag is the correct way to set the working directory filesystem.
