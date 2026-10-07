---@type minimal.pack.spec
return {
  src = 'https://github.com/nvim-treesitter/nvim-treesitter',
  version = 'main', -- master branch is deprecated
  data = {
    build = function()
      vim.cmd.packadd('nvim-treesitter')
      require('nvim-treesitter.install').update()
    end,
    cmds = {
      'TSInstall',
      'TSInstallFromGrammar',
      'TSUninstall',
      'TSUpdate',
    },
    -- Skip loading nvim-treesitter for plugin-specific filetypes containing
    -- underscores (e.g. 'cmp_menu') to improve initial cmdline responsiveness
    -- on slower systems
    events = { event = 'FileType', pattern = '[^_]\\+' },
    postload = function()
      -- Grammars compile on demand via `:TSInstall` (see
      -- modules/editors/vim.nix); ensure the ones Nyx configs depend on
      -- are present, installing once per session when missing.
      local ensured = vim.g._minimal_ts_ensured
      if type(ensured) ~= 'table' then
        ensured = {}
        vim.g._minimal_ts_ensured = ensured
      end
      for _, lang in ipairs({ 'nix' }) do
        if
          not ensured[lang] and not pcall(vim.treesitter.language.add, lang)
        then
          ensured[lang] = true
          vim.schedule(function()
            local ok = false
            local has_install, install =
              pcall(require, 'nvim-treesitter.install')
            if has_install and type(install.install) == 'function' then
              ok = pcall(install.install, lang)
            end
            if not ok then
              ok = pcall(vim.cmd, 'TSInstall ' .. lang)
            end
            if ok then
              vim.notify(
                string.format(
                  '[nvim-treesitter] installed %s parser; reopen %s buffers for highlighting',
                  lang,
                  lang
                ),
                vim.log.levels.INFO
              )
            end
          end)
        end
      end
    end,
  },
}
