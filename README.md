# nvim-semantic-tokens

This is a reference plugin to assist the development of https://github.com/neovim/neovim/pull/15723

## Setup

```lua
require'nvim-semantic-tokens'.setup({
  preset = "default"
})
```

You might want to do a feature tests when you plan to add the snippet above to your config:

```lua
if pcall(require, "vim.lsp.nvim-semantic-tokens") then
  require("nvim-semantic-tokens").setup {
    preset = "default"
    -- highlighters is a list of modules following the interface of nvim-semantic-tokens.table-highlighter or 
    -- function with the signature: highlight_token(ctx, token, highlight) where 
    --        ctx (as defined in :h lsp-handler)
    --        token  (as defined in :h vim.lsp.semantic_tokens.on_full())
    --        highlight (a helper function that you can call (also multiple times) with the determined highlight group(s) as the only parameter)
    highlighters = { require 'nvim-semantic-tokens.table-highlighter'}
  }
end
```

Preset configurations are loaded from [./lua/nvim-semantic-tokens/presets](./lua/nvim-semantic-tokens/presets).
The `"default"` preset will set the highlight groups described in [./doc/nvim-semantic-tokens.txt](./doc/nvim-semantic-tokens.txt).

Use an autocommand for a filetype for which you have a language server set up that supports semantic tokens (e.g. clangd)

```vim
if &filetype == "cpp" || &filetype == "cuda" || &filetype == "c"
  autocmd BufEnter,CursorHold,InsertLeave <buffer> lua require 'vim.lsp.buf'.semantic_tokens_full()
endif
```

or inside an `on_attach` call to a LSP client

```lua
local on_attach = function(client, bufnr)
    if client.resolved_capabilities.semantic_tokens_full then
        vim.cmd [[autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.buf.semantic_tokens_full()]]
    end
    --...
end
```

