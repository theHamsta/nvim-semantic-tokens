local M = {}
local highlighters = {}

local utils = require "nvim-semantic-tokens.utils"
local _, semantic_tokens = pcall(require, "vim.lsp.semantic_tokens")
if not vim.lsp.buf.semantic_tokens_full then
  vim.lsp._request_name_to_capability["textDocument/semanticTokens/full"] = { "semanticTokensProvider" }
  local function request(method, params, handler)
    return vim.lsp.buf_request(0, method, params, handler)
  end
  semantic_tokens = require "nvim-semantic-tokens.semantic_tokens"
  function vim.lsp.buf.semantic_tokens_full()
    local params = { textDocument = require("vim.lsp.util").make_text_document_params() }
    semantic_tokens._save_tick(vim.api.nvim_get_current_buf())
    return request("textDocument/semanticTokens/full", params)
  end
end
local ns = vim.api.nvim_create_namespace "nvim-semantic-tokens"

local function highlight(ctx, token, hl)
  local line_str = vim.api.nvim_buf_get_lines(ctx.bufnr, token.line, token.line + 1, false)[1]
  local ok, start_byte = pcall(vim.lsp.util._str_byteindex_enc, line_str, token.start_char, token.offset_encoding)
  if not ok then
    return
  end
  local ok, end_byte =
    pcall(vim.lsp.util._str_byteindex_enc, line_str, token.start_char + token.length, token.offset_encoding)
  if not ok then
    return
  end
  if #line_str == 0 then
    return
  end
  vim.api.nvim_buf_set_extmark(ctx.bufnr, ns, token.line, start_byte, {
    end_row = token.line,
    end_col = math.min(end_byte, #line_str),
    hl_group = hl,
    -- Highlights from tree-sitter have priority 100, set priority for semantic tokens just above that
    priority = 110,
  })
end

local function highlight_token(ctx, token)
  local function highlight_fn(hl)
    highlight(ctx, token, hl)
  end
  for _, highlighter in ipairs(highlighters) do
    if type(highlighter) == "table" then
      highlighter.highlight_token(ctx, token, highlight_fn)
    else
      highlighter(ctx, token, highlight_fn)
    end
  end
end

local function clear_highlights(ctx, line_start, line_end)
  vim.api.nvim_buf_clear_namespace(ctx.bufnr, ns, line_start, line_end)
end

function M.extend_capabilities(caps)
  caps.textDocument.semanticTokens = {
    dynamicRegistration = false,
    tokenTypes = {
      "namespace",
      "type",
      "class",
      "enum",
      "interface",
      "struct",
      "typeParameter",
      "parameter",
      "variable",
      "property",
      "enumMember",
      "event",
      "function",
      "method",
      "macro",
      "keyword",
      "modifier",
      "comment",
      "string",
      "number",
      "regexp",
      "operator",
      "decorator",
    },
    tokenModifiers = {
      "declaration",
      "definition",
      "readonly",
      "static",
      "deprecated",
      "abstract",
      "async",
      "modification",
      "documentation",
      "defaultLibrary",
    },
    formats = { "relative" },
    requests = {
      -- TODO(smolck): Add support for this
      -- range = true;
      full = { delta = false },
    },

    overlappingTokenSupport = true,
    -- TODO(theHamsta): Add support for this
    multilineTokenSupport = false,
  }
  return caps
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
    if type(h) == "table" and h.reset then
      h.reset()
    end
  end
end

return M
