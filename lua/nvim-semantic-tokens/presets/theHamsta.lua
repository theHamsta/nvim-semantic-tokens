local semantic_tokens = require'nvim-semantic-tokens'

semantic_tokens.modifiers_map["readonly"] = {
  variable = "LspVariableReadOnly",
  method = "Identifier",
}

semantic_tokens.modifiers_map["globalScope"] = { variable = "LspGlobalScope" }
