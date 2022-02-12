local M = {}
local highlighters = {}

local utils = require "nvim-semantic-tokens.utils"
local semantic_tokens = require "vim.lsp.semantic_tokens"
local ns = vim.api.nvim_create_namespace "nvim-semantic-tokens"

local function highlight(buf, token, hl)
  vim.api.nvim_buf_set_extmark(buf, ns, token.line, token.start_char, {
    end_row = token.line,
    end_col = token.start_char + token.length,
    hl_group = hl,
    -- Highlights from tree-sitter have priority 100, set priority for semantic tokens just above that
    priority = 101,
  })
end

local function highlight_token(ctx, token)
  local function highlight_fn(hl)
    highlight(ctx.bufnr, token, hl)
  end
  for _, highlighter in ipairs(highlighters) do
    if type(highlighter) == 'table'then
      highlighter.highlight_token(ctx, token, highlight_fn)
    else
      highlighter(ctx, token, highlight_fn)
    end
  end
end

local function clear_highlights(ctx, line_start, line_end)
  vim.api.nvim_buf_clear_namespace(ctx.bufnr, ns, line_start, line_end)
end

function M.setup(config)
  vim.lsp.handlers["textDocument/semanticTokens/full"] = vim.lsp.with(semantic_tokens.on_full, {
    on_token = highlight_token,
    on_invalidate_range = clear_highlights,
  })
  vim.cmd("luafile " .. utils.get_preset_file "default")
  if config.preset and config.preset ~= "default" then
    vim.cmd("luafile " .. utils.get_preset_file(config.preset))
  end
  highlighters = config.highlighters or { require "nvim-semantic-tokens.table-highlighter" }
  for _, h in ipairs(highlighters) do
    if type(h) == 'table' and h.reset then
      h.reset()
    end
  end
end

return M
