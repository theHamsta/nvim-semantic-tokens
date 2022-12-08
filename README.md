# Important Hint: Semantic Token Support Now Merged to Nightly Neovim: https://github.com/neovim/neovim/pull/21100

Neovim 0.9 will officially support SemanticTokens. See `:h lsp-semantic_tokens` on Neovim 0.9!

# nvim-semantic-tokens

This is a reference plugin to assist the development of https://github.com/neovim/neovim/pull/15723

This plugin will use a local copy of https://github.com/neovim/neovim/pull/15723
if Neovim is built without https://github.com/neovim/neovim/pull/15723. Nightly
Neovim is still required.

## Setup

```lua
require("nvim-semantic-tokens").setup {
  preset = "default",
  -- highlighters is a list of modules following the interface of nvim-semantic-tokens.table-highlighter or 
  -- function with the signature: highlight_token(ctx, token, highlight) where 
  --        ctx (as defined in :h lsp-handler)
  --        token  (as defined in :h vim.lsp.semantic_tokens.on_full())
  --        highlight (a helper function that you can call (also multiple times) with the determined highlight group(s) as the only parameter)
  highlighters = { require 'nvim-semantic-tokens.table-highlighter'}
}
```

Preset configurations are loaded from [./lua/nvim-semantic-tokens/presets](./lua/nvim-semantic-tokens/presets).
The `"default"` preset will set the highlight groups described in [./doc/nvim-semantic-tokens.txt](./doc/nvim-semantic-tokens.txt).
Please map them to colors or highlight groups you like to actually see semantic highlights.

Use an autocommand for a filetype for which you have a language server set up that supports semantic tokens (e.g. clangd)

```vim
if &filetype == "cpp" || &filetype == "cuda" || &filetype == "c"
  autocmd BufEnter,TextChanged <buffer> lua require 'vim.lsp.buf'.semantic_tokens_full()
endif
```

or inside an `on_attach` call to a LSP client

```lua
local on_attach = function(client, bufnr)
    local caps = client.server_capabilities
    if caps.semanticTokensProvider and caps.semanticTokensProvider.full then
      local augroup = vim.api.nvim_create_augroup("SemanticTokens", {})
      vim.api.nvim_create_autocmd("TextChanged", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.semantic_tokens_full()
        end,
      })
      -- fire it first time on load as well
      vim.lsp.buf.semantic_tokens_full()
    end
    --...
end
```

## Language Servers with Semantic Token Support

- clangd
- rust-analyzer
- sumneko-lua
- pyright
- tsserver
- ...
