-- Nix uses 2-space indentation (nixpkgs style, enforced by nixfmt).
-- `iskeyword+=-` and `commentstring` mirror Vim's runtime nix ftplugin so
-- `<cword>`/`gf` cover hyphenated identifiers (e.g. `build-inputs`).
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2
vim.bo.expandtab = true
vim.bo.commentstring = '# %s'
vim.opt_local.iskeyword:append('-')
