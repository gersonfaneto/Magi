" no elisp syntax in neovim and no grammar in nvim-treesitter; CL is close
if exists("b:current_syntax")
  finish
endif

runtime! syntax/lisp.vim

let b:current_syntax = "elisp"
