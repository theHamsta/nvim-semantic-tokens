# nvim-semantic-tokens

This is a reference plugin to assist the development of https://github.com/neovim/neovim/pull/15723

## Setup

```lua
require'nvim-semantic-tokens'.setup({
  preset = "default"
})
```

Preset configurations are loaded from [./lua/nvim-semantic-tokens/presets](./lua/nvim-semantic-tokens/presets).
The `"default"` preset will set the highlight groups described in [./doc/nvim-semantic-tokens.txt](./doc/nvim-semantic-tokens.txt).

Use an autocommand for a filetype for which you have a language server set up that supports semantic tokens (e.g. clangd)

```vim
if &filetype == "cpp" || &filetype == "cuda" || &filetype == "c"
  autocmd BufEnter,CursorHold,InsertLeave <buffer> lua require 'vim.lsp.buf'.semantic_tokens_full()
endif
```
