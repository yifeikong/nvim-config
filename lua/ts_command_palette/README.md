# TS Command Palette

A Telescope command palette for Neovim Ex commands.

Open it with `<leader>p` or `:TSCommandPalette`.

- Type to filter commands.
- Press `Enter` to run the selected command.
- Press `Tab` to search its arguments when completion is available.

For example, select `:colo`, press `Tab`, choose a color scheme, then press
`Enter` to apply it.

The palette reads Neovim's command index and registered user/plugin commands
automatically. Commands with standard or named custom completion get an
argument picker; commands with opaque Lua completion fall back to Neovim's
command line, where normal Tab completion works.

## Configuration

The current config enables the plugin with:

```lua
require("ts_command_palette").setup()
```

You can add personal commands with an optional completion type:

```lua
require("ts_command_palette").setup({
  commands = {
    { "Find files", "Telescope find_files", "files search" },
    { "Choose a color scheme", "colorscheme", "theme", "color" },
  },
})
```
