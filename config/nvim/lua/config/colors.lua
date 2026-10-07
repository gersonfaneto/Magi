local M = {}

M.path = vim.fn.stdpath('state') .. '/colors.lua'

function M.load()
  if not (vim.uv or vim.loop).fs_stat(M.path) then
    return nil, M.path .. ' does not exist yet; has matugen run?'
  end
  local ok, palette = pcall(dofile, M.path)
  if not ok then
    return nil, tostring(palette)
  elseif type(palette) ~= 'table' or not palette.bg then
    return nil, M.path .. ' is not a palette'
  end
  return palette
end

return M
