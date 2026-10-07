" minimal.nvim - A minimal theme with dark/light variants and optional color
" Ported from: https://github.com/bjarneo/vantablack.nvim and
"              https://github.com/bjarneo/white.nvim

if !has('nvim')
  echohl ErrorMsg
  echom "minimal.nvim requires Neovim"
  echohl None
  finish
endif

lua require('minimal.theme').load()
