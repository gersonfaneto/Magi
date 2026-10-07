vim.bo.lisp = true
vim.bo.commentstring = ';; %s'
vim.bo.comments = ':;;;;,:;;;,:;;,:;'

vim.opt_local.iskeyword:append({ '-', '?', '!', '*' })

vim.opt_local.lispwords = {
  'defun',
  'defmacro',
  'defvar',
  'defvar-local',
  'defconst',
  'defcustom',
  'defgroup',
  'defface',
  'defsubst',
  'define-derived-mode',
  'define-minor-mode',
  'cl-defun',
  'cl-defmacro',
  'cl-defmethod',
  'lambda',
  'let',
  'let*',
  'when',
  'unless',
  'while',
  'dolist',
  'dotimes',
  'if-let',
  'when-let',
  'pcase',
  'pcase-let',
  'cond',
  'condition-case',
  'unwind-protect',
  'save-excursion',
  'save-restriction',
  'with-current-buffer',
  'with-temp-buffer',
  'with-eval-after-load',
}
