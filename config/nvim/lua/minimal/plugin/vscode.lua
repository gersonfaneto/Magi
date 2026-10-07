local M = {}

---Set up VSCode-Neovim integration
function M.setup()
  vim.fn['minimal#plugin#vscode#setup']()
end

return M
