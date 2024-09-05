# Neovim terminal Plugin (inspired by [NvChad/nvterm](https://github.com/zbirenbaum/nvterm))

## Install

[lazy.nvim](https://github.com/folke/lazy.nvim)

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

Map the functions below to your prefered keys

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

#### Switch between terminals 

It is possible to spawn multiple horizontal/vertical/floating terminals. You can cycle through the different terminals inside the current window with the function below

```lua
require("simpleterm.terminal").next_term_buffer()
```

### Recommended Configuration
```lua
{
  "oroszarnold12/nvim-simpleterm",
  keys = { "<A-h>", "<A-v>", "<A-i>", "<leader>h", "<leader>v", "<leader>i" },
  config = function()
    require("simpleterm").setup()
    local term = require("simpleterm.terminal")

    vim.keymap.set("t", "<S-TAB>", term.next_term_buffer, { desc = "Next Terminal Buffer" })
    vim.keymap.set("t", "<A-h>", term.toggle_horizontal, { desc = "Toggle Horizontal Terminal" })
    vim.keymap.set("t", "<A-v>", term.toggle_vertical, { desc = "Toggle Vertical Terminal" })
    vim.keymap.set("t", "<A-i>", term.toggle_floating, { desc = "Toggle Floating Terminal" })
    vim.keymap.set("n", "<A-h>", term.toggle_horizontal, { desc = "Toggle Horizontal Terminal" })
    vim.keymap.set("n", "<A-v>", term.toggle_vertical, { desc = "Toggle Vertical Terminal" })
    vim.keymap.set("n", "<A-i>", term.toggle_floating, { desc = "Toggle Floating Terminal" })
    vim.keymap.set("n", "<leader>h", term.new_horizontal, { desc = "New Horizontal Terminal" })
    vim.keymap.set("n", "<leader>v", term.new_vertical, { desc = "New Vertical Terminal" })
    vim.keymap.set("n", "<leader>i", term.new_floating, { desc = "new Floating Terminal" })
  end,
}
```
