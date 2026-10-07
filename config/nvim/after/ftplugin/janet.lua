vim.bo.lisp = true
vim.bo.commentstring = '# %s'
vim.bo.comments = ':###,:##,:#'

vim.opt_local.iskeyword:append({ '-', '?', '!', '*', '/' })

vim.opt_local.lispwords = {
  'def',
  'def-',
  'defn',
  'defn-',
  'defmacro',
  'defmacro-',
  'defer',
  'varfn',
  'fn',
  'do',
  'if',
  'when',
  'when-let',
  'when-with',
  'unless',
  'cond',
  'case',
  'match',
  'let',
  'loop',
  'seq',
  'each',
  'eachp',
  'eachk',
  'while',
  'with',
  'with-dyns',
  'try',
  'forever',
}
