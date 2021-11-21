local M = {}

local utils = require "nvim-semantic-tokens.utils"
local semantic_tokens = require "vim.lsp.semantic_tokens"
local ns = vim.api.nvim_create_namespace "nvim-semantic-tokens"

M.token_map = {}
M.modifiers_map = {}

--- transforms a highlight group string or a table of highlight group strings
local function define_prefixed_hl(ft, hl)
  local prefixed
  if type(hl) == "table" then
    prefixed = {}
    for k, sub_hl in pairs(hl) do
      prefixed[k] = define_prefixed_hl(ft, sub_hl)
    end
  else
    prefixed = ft .. hl
    vim.cmd("highlight default link " .. prefixed .. " " .. hl)
  end
  return prefixed
end

local function make_cache(base_map)
  -- two-stage look-up: ft-> token -> highlight
  -- two-stage look-up: ft-> modifier -> highlight (or per-token table for three stage look-up)
  return setmetatable({}, {
    __index = function(ft_cache, ft)
      local rtn = setmetatable({}, {
        __index = function(hl_cache, query)
          local hl = base_map[query]
          if hl then
            local prefixed = define_prefixed_hl(ft, hl)
            rawset(hl_cache, query, prefixed)
            return prefixed
          end
          return hl
        end,
      })
      rawset(ft_cache, ft, rtn)
      return rtn
    end,
  })
end

local token_cache
local modifiers_cache

local function reset_cache()
  token_cache = make_cache(M.token_map)
  modifiers_cache = make_cache(M.modifiers_map)
end

local function highlight(buf, token, hl)
  vim.highlight.range(buf, ns, hl, { token.line, token.start_char }, { token.line, token.start_char + token.length })
end

local function highlight_token(ctx, token)
  local buf = ctx.bufnr
  local ft = vim.api.nvim_buf_get_option(buf, "filetype")
  local ft_token_cache = token_cache[ft]
  local ft_modifiers_cache = modifiers_cache[ft]

  local hl = ft_token_cache[token.type]
  if hl then
    highlight(buf, token, hl)
  end
  for _, m in pairs(token.modifiers) do
    hl = ft_modifiers_cache[m]
    -- modifiers can have a per-type mapping
    -- e.g. readonly = { variable = "ReadOnlyVariable" }
    if type(hl) == "table" then
      hl = hl[token.type]
    end
    if hl then
      highlight(buf, token, hl)
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
  if config.preset then
    vim.cmd("luafile " .. utils.get_preset_file(config.preset))
  end
  reset_cache()
end

return M
