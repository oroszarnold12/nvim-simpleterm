# Neovim terminal Plugin (inspired by NvChad/nvterm)

## Install

- Simply install the plugin with lazy.nvim as you would for any other:

```lua
{
  "oroszarnold12/nvim-simpleterm",
  config = function ()
    require("simpleterm").setup()
  end,
}
```

### Configuration

- Pass a table of configuration options to the plugin's `.setup()` function above.
- Default configuration table

```lua
require("nvterm").setup({
  type_opts = {
    horizontal = { location = "rightbelow", split_ratio = 0.3 },
    vertical = { location = "rightbelow", split_ratio = 0.5 },
    floating = {
      relative = "editor",
      row = 0.3,
      col = 0.25,
      width = 0.5,
      height = 0.4,
      border = "single",
    },
  },
  behavior = {
    autoclose_on_quit = {
      enabled = false,
      confirm = true,
    },
    close_on_exit = true,
    auto_insert = true,
  },
})
```

### Functions

Use the below functions to map them for keybindings

#### Toggle

```lua
require("simpleterm.terminal").toggle_horizontal()
require("simpleterm.terminal").toggle_vertical()
require("simpleterm.terminal").toggle_floating()
```

#### Spawn new terminals

```lua
require("simpleterm.terminal").new_horizontal()
require("simpleterm.terminal").new_vertical()
require("simpleterm.terminal").new_floating()
```
