local M = {}

---@param c table
---@param opts table
-- luacheck: no unused args
function M.get(c, opts)
  -- stylua: ignore
  return {
    ['@lsp.type.class']         = { link = 'Structure' },
    ['@lsp.type.decorator']     = { link = 'Function' },
    ['@lsp.type.enum']          = { link = 'Type' },
    ['@lsp.type.enumMember']    = { link = 'Constant' },
    ['@lsp.type.function']      = { link = 'Function' },
    ['@lsp.type.interface']     = { link = 'Structure' },
    ['@lsp.type.macro']         = { link = 'Macro' },
    ['@lsp.type.method']        = { link = 'Function' },
    ['@lsp.type.namespace']     = { link = 'Include' },
    ['@lsp.type.parameter']     = { link = 'Identifier' },
    ['@lsp.type.property']      = { link = 'Identifier' },
    ['@lsp.type.struct']        = { link = 'Structure' },
    ['@lsp.type.type']          = { link = 'Type' },
    ['@lsp.type.typeParameter'] = { link = 'Typedef' },
    ['@lsp.type.variable']      = { link = 'Identifier' },
  }
end

return M
