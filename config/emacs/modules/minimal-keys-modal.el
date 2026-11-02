;;; minimal-keys-modal.el --- Neovim-like modal keys and leader -*- lexical-binding: t; -*-

;;; Commentary:
;; Evil supplies Vim's modal editing and general.el supplies the SPC leader.
;; The tree mirrors config/nvim key-for-key where Emacs has an equivalent:
;; windows live on M-* and tabs on TAB, the leader covers pickers, LSP, git,
;; tests and debug, and the extra groups at the end have no Neovim peer.

;;; Code:

(require 'cl-lib)
(require 'desktop)
(require 'ffap)
(require 'flymake)
(require 'project)
(require 'smerge-mode)
(require 'tab-bar)
(require 'windmove)

;; --- Helpers ---
(defun minimal/consult-ripgrep-at-point ()
  "Search the project for the symbol at point."
  (interactive)
  (consult-ripgrep nil (thing-at-point 'symbol t)))

(defun minimal/open-init-file ()
  "Open the user's init.el."
  (interactive)
  (find-file user-init-file))

(defun minimal/zoxide-directories ()
  "Return the directories recorded by zoxide."
  (split-string (shell-command-to-string "zoxide query -l") "\n" t))

(defun minimal/zoxide-dired ()
  "Open a directory picked from zoxide in Dired."
  (interactive)
  (dired (completing-read "Directory: " (minimal/zoxide-directories) nil t)))

(defun minimal/goto-definition ()
  "Jump to the definition of the symbol at point.
Use the language server when one manages the buffer, and fall back to
`evil-goto-definition' otherwise, matching Neovim's `gd'."
  (interactive)
  (if (eglot-managed-p)
      (xref-find-definitions (thing-at-point 'symbol t))
    (evil-goto-definition)))

(defun minimal/fold-others ()
  "Hide every block except the one around point."
  (interactive)
  (hs-hide-all)
  (hs-show-block))

(defun minimal/fix-elisp-gz ()
  "Keep `gz' on `evil-goto-last-change' in Emacs Lisp buffers.
`evil-collection' binds it to `ielm' there, shadowing the global map."
  (evil-local-set-key 'normal (kbd "gz") #'evil-goto-last-change))

(add-hook 'emacs-lisp-mode-hook #'minimal/fix-elisp-gz)

(defmacro minimal/define-tab-selectors ()
  "Define `minimal/tab-select-N' for tabs 0 through 9.
Tab 0 selects the last tab, as in `tab-bar-select-tab'."
  (declare (indent 0))
  `(progn
     ,@(mapcar
        (lambda (n)
          `(defun ,(intern (format "minimal/tab-select-%d" n)) ()
             ,(format "Select tab %d (0 selects the last tab)." n)
             (interactive)
             (tab-bar-select-tab ,n)))
        (number-sequence 0 9))))

(minimal/define-tab-selectors)

(defun minimal/diagnostic-at-point ()
  "Show the Flymake diagnostics covering point."
  (interactive)
  (let ((diags (flymake-diagnostics (point))))
    (if diags
        (message "%s" (mapconcat #'flymake-diagnostic-text diags "\n"))
      (message "No diagnostics at point"))))

(defun minimal/yank-diagnostic ()
  "Copy the Flymake diagnostic message(s) on the current line."
  (interactive)
  (let ((diags (flymake-diagnostics (line-beginning-position)
                                    (line-end-position))))
    (unless diags
      (user-error "No diagnostics on this line"))
    (kill-new (if (= 1 (length diags))
                   (flymake-diagnostic-text (car diags))
                 (completing-read "Diagnostic: "
                                  (mapcar #'flymake-diagnostic-text diags))))
    (message "Yanked diagnostic message")))

(defmacro minimal/define-flymake-jumps ()
  "Define severity-specific Flymake jump commands."
  (declare (indent 0))
  `(progn
     ,@(cl-loop
        for (name type) in '(("error" :error) ("warning" :warning) ("note" :note))
        append
        (list
         `(defun ,(intern (format "minimal/next-%s-diagnostic" name)) ()
            ,(format "Jump to the next %s diagnostic." name)
            (interactive)
            (flymake-goto-next-error
             1 (lambda (diag) (eq (flymake-diagnostic-type diag) ,type)) t))
         `(defun ,(intern (format "minimal/prev-%s-diagnostic" name)) ()
            ,(format "Jump to the previous %s diagnostic." name)
            (interactive)
            (flymake-goto-prev-error
             1 (lambda (diag) (eq (flymake-diagnostic-type diag) ,type)) t))))))

(minimal/define-flymake-jumps)

(defun minimal/quit-or-record-macro ()
  "Delete a popup or side window, otherwise record a macro."
  (interactive)
  (if (or (window-parameter (selected-window) 'window-side)
          (window-dedicated-p (selected-window)))
      (delete-window)
    (call-interactively #'evil-record-macro)))

(defun minimal/insert-space ()
  "Enter insert state after point and leave a trailing space."
  (interactive)
  (evil-insert 1)
  (insert " ")
  (backward-char))

(defun minimal/insert-space-line-start ()
  "Enter insert state at line start and leave a trailing space."
  (interactive)
  (evil-insert-line 1)
  (insert " ")
  (backward-char))

(defun minimal/append-space ()
  "Enter insert state after the cursor and leave a trailing space."
  (interactive)
  (evil-append 1)
  (insert " ")
  (backward-char))

(defun minimal/append-space-line-end ()
  "Enter insert state at line end and leave a trailing space."
  (interactive)
  (evil-append-line 1)
  (insert " ")
  (backward-char))

(defun minimal/dap-repl ()
  "Open the DAP REPL buffer, loading `dap-ui' on demand."
  (interactive)
  (require 'dap-ui)
  (dap-ui-repl))

;; --- Evil ---
(use-package evil
  :straight t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-d-scroll t
        evil-want-C-i-jump t
        evil-undo-system 'undo-redo
        evil-respect-visual-line-mode t
        evil-vsplit-window-right t
        evil-split-window-below t)
  :config
  (evil-mode 1))

(use-package evil-collection
  :straight t
  :after evil
  :init
  ;; Neovim's [e/]e and friends are diagnostics, not Unimpaired's move-text.
  (setq evil-collection-want-unimpaired-p nil)
  :config
  (evil-collection-init))

;; --- Dired ---
;; `evil-motion-state-map' owns `,' and `_', so plain `dired-mode-map'
;; bindings for them never fire. Bind them in Evil's local normal state
;; map, the way `evil-collection' does, and keep `,' a subtree.
(defvar minimal/dired-leader-map
  (let ((map (make-sparse-keymap)))
    (define-key map "." #'dired-omit-mode)
    (define-key map "c" #'dired-do-copy)
    (define-key map "d" #'dired-hide-details-mode)
    (define-key map "g" #'dired-mark-files-containing-regexp)
    (define-key map "h" #'dired-hide-details-mode)
    (define-key map "m" #'dired-mark-files-regexp)
    (define-key map "n" #'dired-create-directory)
    (define-key map "o" #'+dired/open-with-external-program)
    (define-key map "r" #'dired-do-rename)
    (define-key map "s" #'dired-do-shell-command)
    (define-key map "u" #'dired-unmark-all-marks)
    map)
  "Dired leader, mirroring Neovim's `,' group.")

(defun minimal/dired-evil-keys ()
  "Install Dired keys that Evil's motion map would otherwise shadow."
  (evil-local-set-key 'normal (kbd ",") minimal/dired-leader-map)
  (evil-local-set-key 'normal (kbd "-") #'dired-up-directory)
  (evil-local-set-key 'normal (kbd "+") #'+dired/create-directory)
  (evil-local-set-key 'normal (kbd "_") #'+dired/create-empty-file))

(add-hook 'dired-mode-hook #'minimal/dired-evil-keys)

(use-package evil-surround
  :straight t
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-args
  :straight t
  :after evil
  :config
  (require 'evil-args))

(use-package evil-indent-plus
  :straight t
  :after evil
  :config
  (require 'evil-indent-plus))

(use-package evil-textobj-anyblock
  :straight t
  :after evil
  :config
  (require 'evil-textobj-anyblock))

(use-package evil-textobj-entire
  :straight t
  :after evil
  :config
  (require 'evil-textobj-entire))

(use-package evil-textobj-tree-sitter
  :straight t
  :after evil
  :config
  (require 'evil-textobj-tree-sitter))

;; --- Tree-sitter Text Objects ---
;; Neovim's tree-sitter text objects, with the previous indentation-based
;; objects as the fallback for buffers without a parser.
(defun minimal/tree-sitter-parser-p ()
  "Return non-nil when the current buffer has a tree-sitter parser."
  (and (fboundp 'treesit-parser-list)
       (treesit-parser-list)
       t))

(defun minimal/textobj-range (group count fallback beg end type)
  "Return the tree-sitter text object GROUP, or FALLBACK.
GROUP is a nvim-treesitter capture such as \"function.inner\". FALLBACK is
an Evil text object function used when the buffer has no parser."
  (let ((range (and (minimal/tree-sitter-parser-p)
                    (ignore-errors
                      (evil-textobj-tree-sitter--range
                       count (list (intern group)))))))
    (if range
        (evil-range (car range) (cdr range))
      (funcall fallback count beg end type))))

(defmacro minimal/define-textobject (name group inner outer &optional object-type)
  "Define inner and outer Evil text objects for GROUP named NAME.
INNER and OUTER are the fallback text objects used without a parser.
OBJECT-TYPE selects the Evil motion type, such as `line'."
  (declare (indent 1))
  `(progn
     (evil-define-text-object ,(intern (format "minimal/inner-%s" name))
       (count &optional beg end type)
       ,(format "Select inside a %s." name)
       ,@(when object-type `(:type ,object-type))
       (minimal/textobj-range ,(concat group ".inner") count ,inner beg end type))
     (evil-define-text-object ,(intern (format "minimal/outer-%s" name))
       (count &optional beg end type)
       ,(format "Select around a %s." name)
       ,@(when object-type `(:type ,object-type))
       (minimal/textobj-range ,(concat group ".outer") count ,outer beg end type))))

(minimal/define-textobject function "function"
                           #'evil-indent-plus-i-indent #'evil-indent-plus-a-indent)
(minimal/define-textobject loop "loop"
                           #'evil-indent-plus-i-indent #'evil-indent-plus-a-indent)
(minimal/define-textobject class "class"
                           #'evil-indent-plus-i-indent #'evil-indent-plus-a-indent)
(minimal/define-textobject parameter "parameter"
                           #'evil-inner-arg #'evil-outer-arg)
(minimal/define-textobject comment "comment"
                           #'evil-inner-symbol #'evil-inner-symbol)
(minimal/define-textobject block "block"
                           #'evil-textobj-anyblock-inner-block
                           #'evil-textobj-anyblock-a-block line)
(minimal/define-textobject conditional "conditional"
                           #'evil-inner-symbol #'evil-inner-symbol)
(minimal/define-textobject assignment "assignment"
                           #'evil-inner-symbol #'evil-inner-symbol)
(minimal/define-textobject header "header"
                           #'evil-inner-symbol #'evil-inner-symbol line)
(minimal/define-textobject return "return"
                           #'evil-inner-symbol #'evil-inner-symbol)

(define-key evil-inner-text-objects-map "f" #'minimal/inner-function)
(define-key evil-outer-text-objects-map "f" #'minimal/outer-function)
(define-key evil-inner-text-objects-map "m" #'minimal/inner-function)
(define-key evil-outer-text-objects-map "m" #'minimal/outer-function)
(define-key evil-inner-text-objects-map "o" #'minimal/inner-loop)
(define-key evil-outer-text-objects-map "o" #'minimal/outer-loop)
(define-key evil-inner-text-objects-map "k" #'minimal/inner-class)
(define-key evil-outer-text-objects-map "k" #'minimal/outer-class)
(define-key evil-inner-text-objects-map "," #'minimal/inner-parameter)
(define-key evil-outer-text-objects-map "," #'minimal/outer-parameter)
(define-key evil-inner-text-objects-map "/" #'minimal/inner-comment)
(define-key evil-outer-text-objects-map "/" #'minimal/outer-comment)
(define-key evil-inner-text-objects-map "*" #'minimal/inner-comment)
(define-key evil-outer-text-objects-map "*" #'minimal/outer-comment)
(define-key evil-inner-text-objects-map "." #'minimal/inner-block)
(define-key evil-outer-text-objects-map "." #'minimal/outer-block)
(define-key evil-inner-text-objects-map "?" #'minimal/inner-conditional)
(define-key evil-outer-text-objects-map "?" #'minimal/outer-conditional)
(define-key evil-inner-text-objects-map "=" #'minimal/inner-assignment)
(define-key evil-outer-text-objects-map "=" #'minimal/outer-assignment)
(define-key evil-inner-text-objects-map "#" #'minimal/inner-header)
(define-key evil-outer-text-objects-map "#" #'minimal/outer-header)
(define-key evil-inner-text-objects-map "3" #'minimal/inner-header)
(define-key evil-outer-text-objects-map "3" #'minimal/outer-header)
(define-key evil-inner-text-objects-map "r" #'minimal/inner-return)
(define-key evil-outer-text-objects-map "r" #'minimal/outer-return)
(define-key evil-inner-text-objects-map "e" #'evil-entire-entire-buffer)
(define-key evil-outer-text-objects-map "e" #'evil-entire-entire-buffer)

(defmacro minimal/define-tree-sitter-motions ()
  "Define Neovim's tree-sitter motions."
  (declare (indent 0))
  `(progn
     ,@(cl-loop
        for (name group) in '(("function" "function.outer")
                              ("loop" "loop.outer")
                              ("class" "class.outer")
                              ("parameter" "parameter.outer")
                              ("comment" "comment.outer")
                              ("block" "block.outer")
                              ("conditional" "conditional.outer")
                              ("assignment" "assignment.outer")
                              ("header" "header.outer"))
        append
        (list
         `(defun ,(intern (format "minimal/next-%s-start" name)) ()
            ,(format "Move to the next start of a %s." name)
            (interactive)
            (evil-textobj-tree-sitter-goto-textobj ,group))
         `(defun ,(intern (format "minimal/prev-%s-start" name)) ()
            ,(format "Move to the previous start of a %s." name)
            (interactive)
            (evil-textobj-tree-sitter-goto-textobj ,group t))
         `(defun ,(intern (format "minimal/next-%s-end" name)) ()
            ,(format "Move to the next end of a %s." name)
            (interactive)
            (evil-textobj-tree-sitter-goto-textobj ,group nil t))
         `(defun ,(intern (format "minimal/prev-%s-end" name)) ()
            ,(format "Move to the previous end of a %s." name)
            (interactive)
            (evil-textobj-tree-sitter-goto-textobj ,group t t))))))

(minimal/define-tree-sitter-motions)

(evil-define-key '(normal visual operator motion) 'global
 "]m" #'minimal/next-function-start
 "[m" #'minimal/prev-function-start
 "]M" #'minimal/next-function-end
 "[M" #'minimal/prev-function-end
 "]]" #'minimal/next-function-start
 "[[" #'minimal/prev-function-start
 "][" #'minimal/next-function-end
 "[]" #'minimal/prev-function-end
 "]o" #'minimal/next-loop-start
 "[o" #'minimal/prev-loop-start
 "]O" #'minimal/next-loop-end
 "[O" #'minimal/prev-loop-end
 "]k" #'minimal/next-class-start
 "[k" #'minimal/prev-class-start
 "]K" #'minimal/next-class-end
 "[K" #'minimal/prev-class-end
 "]," #'minimal/next-parameter-start
 "[," #'minimal/prev-parameter-start
 "]/" #'minimal/next-comment-end
 "[/" #'minimal/prev-comment-end
 "]." #'minimal/next-block-start
 "[." #'minimal/prev-block-start
 "]?" #'minimal/next-conditional-start
 "[?" #'minimal/prev-conditional-start
 "]=" #'minimal/next-assignment-start
 "[=" #'minimal/prev-assignment-start
 "]#" #'minimal/next-header-start
 "[#" #'minimal/prev-header-start
 "]3" #'minimal/next-header-start
 "[3" #'minimal/prev-header-start)

;; --- Supporting packages ---
(use-package diff-hl
  :straight t
  :hook ((prog-mode . turn-on-diff-hl-mode)
         (dired-mode . turn-on-diff-hl-mode)))

;; `origami' requires the deprecated `cl' package, so use the built-in
;; hideshow minor mode for the Neovim fold keys instead. Some tree-sitter
;; modes define no comment syntax, and Hideshow refuses to start there.
(defun minimal/enable-hideshow ()
  "Enable Hideshow when the major mode knows how comments work."
  (when (and comment-start comment-end)
    (hs-minor-mode 1)))

(use-package hideshow
  :straight nil
  :ensure nil
  :hook (prog-mode . minimal/enable-hideshow))

(use-package vundo
  :straight (:host github :repo "casouri/vundo")
  :commands (vundo))

(use-package dap-mode
  :straight t
  :commands (dap-breakpoint-condition dap-breakpoint-log-message
             dap-breakpoint-toggle dap-continue dap-debug dap-debug-restart
             dap-disconnect dap-down-stack-frame dap-next dap-step-in
             dap-step-out dap-up-stack-frame))

;; --- Leader ---
(use-package general
  :straight t
  :after evil
  :config
  (general-create-definer minimal-leader
    :states '(normal visual motion)
    :prefix "SPC")

  (minimal-leader
    ;; Make SPC a real prefix. SPC SPC is the generic command prompt.
    ""    '(nil :wk "leader")
    "SPC" '(execute-extended-command :wk "Commands")
    "?"   '(consult-info :wk "Help")
    "<escape>" '(vertico-repeat :wk "Resume last picker")

    ;; --- Single-key pickers (Neovim parity) ---
    "."   '(consult-find :wk "Find files")
    ","   '(consult-buffer :wk "Switch buffer")
    "/"   '(consult-ripgrep :wk "Grep")
    "-"   '(consult-line :wk "Lines in buffer")
    "="   '(consult-line-multi :wk "Lines across buffers")
    "*"   '(minimal/consult-ripgrep-at-point :wk "Grep word at point")
    "#"   '(minimal/consult-ripgrep-at-point :wk "Grep word at point")
    "\""  '(consult-yank-from-kill-ring :wk "Kill ring")
    ":"   '(execute-extended-command :wk "Commands")
    "%"   '(tab-bar-switch-to-tab :wk "Switch tab")
    "`"   '(consult-mark :wk "Marks")
    "o"   '(consult-recent-file :wk "Recent files")
    "F"   '(consult-buffer :wk "All pickers")
    ";"   '(consult-imenu :wk "Pick symbol")
    "n"   '(consult-imenu :wk "Nodes")
    "R"   '(consult-eglot-symbols :wk "Symbol locations")
    "u"   '(vundo :wk "Undo tree")

    ;; --- LSP ---
    "a"   '(eglot-code-actions :wk "Code actions")
    "r"   '(eglot-rename :wk "Rename symbol")
    "d"   '(flymake-show-buffer-diagnostics :wk "Document diagnostics")
    "D"   '(flymake-show-project-diagnostics :wk "Workspace diagnostics")
    "i"   '(minimal/diagnostic-at-point :wk "Diagnostic at point")
    "s"   '(consult-imenu :wk "Document symbols")
    "S"   '(consult-eglot-symbols :wk "Workspace symbols")
    "<"   '(eglot-show-call-hierarchy :wk "Call hierarchy")
    ">"   '(eglot-show-call-hierarchy :wk "Call hierarchy")

    ;; --- Sessions and directories ---
    "w"   '(desktop-read :wk "Load session")
    "W"   '(desktop-save :wk "Save session")
    "z"   '(minimal/zoxide-dired :wk "Directory from zoxide")

    ;; --- g - git ---
    "g"   '(:ignore t :wk "git")
    "gg"  '(magit-status :wk "Status")
    "gd"  '(magit-diff-buffer-with-reference :wk "Diff current file")
    "gw"  '(magit-show-commit :wk "Show commit")
    "gb"  '(magit-branch-checkout :wk "Branches")
    "gc"  '(magit-commit-create :wk "Commit")
    "gP"  '(magit-push :wk "Push")
    "gD"  '(magit-diff :wk "Diff repo")
    "gB"  '(magit-blame :wk "Blame")
    "gl"  '(magit-log-current :wk "Log (buffer)")
    "gL"  '(magit-log :wk "Log")
    "g."  '(git-link-dispatch :wk "Browse")
    "gm"  '(magit-dispatch :wk "Magit dispatch")
    "gu"  '(diff-hl-unstage-file :wk "Unstage file")
    "gs"  '(diff-hl-stage-current-hunk :wk "Stage hunk")
    "gr"  '(diff-hl-revert-hunk :wk "Revert hunk")
    "gU"  '(diff-hl-unstage-file :wk "Unstage file")
    "gS"  '(diff-hl-stage-dwim :wk "Stage buffer")
    "gR"  '(diff-hl-revert-hunk :wk "Revert hunk")
    "gp"  '(diff-hl-show-hunk :wk "Preview hunk")
    "gh"  '(diff-hl-diff-goto-hunk :wk "Goto hunk")
    "gH"  '(magit-status :wk "List hunks")

    ;; --- f - pickers (Neovim's fzf-lua tree) ---
    "f"   '(:ignore t :wk "find")
    "fb"  '(consult-buffer :wk "Buffers")
    "fF"  '(consult-buffer :wk "All pickers")
    "f/"  '(consult-ripgrep :wk "Grep")
    "f*"  '(minimal/consult-ripgrep-at-point :wk "Grep word")
    "f#"  '(minimal/consult-ripgrep-at-point :wk "Grep word")
    "f:"  '(execute-extended-command :wk "Commands")
    "f\"" '(consult-yank-from-kill-ring :wk "Registers")
    "fh"  '(consult-info :wk "Help")
    "fk"  '(describe-key :wk "Keymaps")
    "ff"  '(consult-find :wk "Files")
    "f."  '(consult-find :wk "Files")
    "f-"  '(consult-line :wk "Lines in buffer")
    "f="  '(consult-line-multi :wk "Lines across buffers")
    "fd"  '(flymake-show-buffer-diagnostics :wk "Document diagnostics")
    "fD"  '(flymake-show-project-diagnostics :wk "Workspace diagnostics")
    "fl"  '(flymake-show-buffer-diagnostics :wk "Location list")
    "fq"  '(flymake-show-project-diagnostics :wk "Quickfix list")
    "fm"  '(consult-mark :wk "Marks")
    "fo"  '(consult-recent-file :wk "Old files")
    "fp"  '(tab-bar-switch-to-tab :wk "Tabpages")
    "fz"  '(minimal/zoxide-dired :wk "Directories from z")
    "fw"  '(desktop-read :wk "Sessions")
    "fn"  '(consult-imenu :wk "Nodes")
    "fs"  '(consult-imenu :wk "Symbols")
    "fc"  '(diff-hl-diff-goto-hunk :wk "Changes")
    "fu"  '(vundo :wk "Undos")
    "ft"  '(xref-find-apropos :wk "Tags")
    "f <escape>" '(vertico-repeat :wk "Resume last picker")

    "fS"  '(:ignore t :wk "LSP")
    "fSa" '(eglot-code-actions :wk "Code actions")
    "fSd" '(xref-find-definitions :wk "Definitions")
    "fSD" '(eglot-find-declaration :wk "Declarations")
    "fSt" '(eglot-find-typeDefinition :wk "Type definition")
    "fSs" '(consult-imenu :wk "Document symbols")
    "fSS" '(consult-eglot-symbols :wk "Workspace symbols")
    "fSi" '(eglot-find-implementation :wk "Implementations")
    "fS<" '(eglot-show-call-hierarchy :wk "Incoming calls")
    "fS>" '(eglot-show-call-hierarchy :wk "Outgoing calls")
    "fSr" '(xref-find-references :wk "References")
    "fSR" '(consult-eglot-symbols :wk "Symbol locations")

    "fg"  '(:ignore t :wk "Git")
    "fgg" '(magit-status :wk "Status")
    "fgl" '(magit-log-current :wk "Log (buffer)")
    "fgL" '(magit-log :wk "Log")
    "fgb" '(magit-branch-checkout :wk "Branches")
    "fgB" '(magit-blame :wk "Blame")
    "fgc" '(magit-commit-create :wk "Commit")
    "fgd" '(magit-diff-buffer-with-reference :wk "Diff current file")
    "fgf" '(project-find-file :wk "Git files")
    "fgp" '(magit-push :wk "Push")
    "fgr" '(magit-diff :wk "Diff repo")
    "fgs" '(magit-status :wk "Status")
    "fgt" '(magit-tag :wk "Tags")

    ;; --- t - tests (Neovim's vim-test tree) ---
    "t"   '(:ignore t :wk "test")
    "tk"  '(compile :wk "Test class")
    "tf"  '(compile :wk "Test file")
    "tt"  '(project-compile :wk "Test nearest")
    "tr"  '(recompile :wk "Test last")
    "ts"  '(project-compile :wk "Test suite")
    "to"  '(project-switch-project :wk "Visit test project")
    "tg"  '(compile :wk "Test strategy")

    ;; --- G - debug (Neovim's dap tree) ---
    "G"   '(:ignore t :wk "debug")
    "Gc"  '(dap-continue :wk "Continue")
    "Gg"  '(dap-continue :wk "Continue")
    "GG"  '(dap-continue :wk "Continue")
    "Gh"  '(dap-disconnect :wk "Stop")
    "Gp"  '(dap-disconnect :wk "Stop")
    "Ge"  '(minimal/dap-repl :wk "Debug REPL")
    "Gb"  '(dap-breakpoint-toggle :wk "Toggle breakpoint")
    "GB"  '(dap-breakpoint-condition :wk "Conditional breakpoint")
    "Gl"  '(dap-breakpoint-log-message :wk "Logpoint")
    "Gn"  '(dap-next :wk "Step over")
    "Gi"  '(dap-step-in :wk "Step into")
    "Go"  '(dap-step-out :wk "Step out")
    "Gt"  '(dap-disconnect :wk "Terminate")
    "Gx"  '(dap-disconnect :wk "Terminate")
    "Gr"  '(dap-debug-restart :wk "Restart")
    "Gk"  '(dap-up-stack-frame :wk "Stack up")
    "Gj"  '(dap-down-stack-frame :wk "Stack down")

    ;; --- P - packages ---
    "P"   '(:ignore t :wk "plugins")
    "Pu"  '(straight-pull-all :wk "Update plugins")
    "Pr"  '(straight-thaw-versions :wk "Restore from lockfile")
    "Pd"  '(straight-remove-unused-repos :wk "Delete plugin")

    ;; --- O - org (displaced from a) ---
    "O"   '(:ignore t :wk "org")
    "Oa"  '(org-agenda :wk "Agenda")
    "Ob"  '(org-switchb :wk "Switch org buffer")
    "Oc"  '(org-capture :wk "Capture")
    "Ol"  '(org-store-link :wk "Store link")

    ;; --- b - buffers ---
    "b"   '(:ignore t :wk "buffers")
    "bi"  '(ibuffer :wk "ibuffer")
    "bk"  '(kill-current-buffer :wk "Kill buffer")
    "br"  '(kill-buffer :wk "Kill buffer (prompt)")
    "bs"  '(save-buffer :wk "Save buffer")
    "bt"  '(revert-buffer-quick :wk "Revert buffer")

    ;; --- c - code ---
    "c"   '(:ignore t :wk "code")
    "ca"  '(eglot-code-actions :wk "Code actions")
    "cb"  '(xref-go-back :wk "Jump back")
    "cd"  '(xref-find-definitions :wk "Find definition")
    "cD"  '(xref-find-references :wk "Find references")
    "cf"  '(eglot-format :wk "Format buffer")
    "ci"  '(eglot-code-action-organize-imports :wk "Organize imports")
    "ck"  '(eldoc-doc-buffer :wk "Documentation")
    "cm"  '(eglot-find-implementation :wk "Find implementation")
    "cr"  '(eglot-rename :wk "Rename symbol")
    "cs"  '(eglot-shutdown :wk "Shutdown eglot")
    "cS"  '(eglot :wk "Start eglot")
    "ct"  '(eglot-find-typeDefinition :wk "Find type definition")
    "cw"  '(consult-eglot-symbols :wk "Workspace symbols")

    ;; --- e - eval ---
    "e"   '(:ignore t :wk "eval")
    "eb"  '(eval-buffer :wk "Eval buffer")
    "ed"  '(eval-defun :wk "Eval defun")
    "ei"  '(ielm :wk "ielm")
    "el"  '(eval-last-sexp :wk "Eval sexp")
    "er"  '(eval-region :wk "Eval region")

    ;; --- k - kmacro ---
    "k"   '(:ignore t :wk "kmacro")
    "kk"  '(kmacro-end-or-call-macro-repeat :wk "Run macro")
    "kn"  '(kmacro-name-last-macro :wk "Name last macro")
    "kb"  '(kmacro-bind-to-key :wk "Bind macro to key")
    "ki"  '(insert-kbd-macro :wk "Insert macro as elisp")
    "ke"  '(kmacro-edit-macro :wk "Edit macro")
    "ks"  '(kmacro-step-edit-macro :wk "Step-edit macro")
    "kl"  '(kmacro-edit-lossage :wk "Last 300 keys as macro")
    "kv"  '(kmacro-view-macro-repeat :wk "View macro")
    "km"  '(kmacro-menu :wk "Macro ring")
    "kr"  '(apply-macro-to-region-lines :wk "Apply to region lines")
    "kx"  '(kmacro-to-register :wk "Macro to register")
    "kq"  '(kbd-macro-query :wk "Query during macro")
    "kc"  '(kmacro-set-counter :wk "Set counter")
    "ka"  '(kmacro-add-counter :wk "Add to counter")
    "kf"  '(kmacro-set-format :wk "Counter format")
    "kt"  '(kmacro-insert-counter :wk "Insert counter")
    "kN"  '(kmacro-cycle-ring-next :wk "Ring next")
    "kP"  '(kmacro-cycle-ring-previous :wk "Ring previous")
    "kT"  '(kmacro-swap-ring :wk "Swap ring head")
    "kD"  '(kmacro-delete-ring-head :wk "Delete ring head")

    ;; --- l - loading ---
    "l"   '(:ignore t :wk "loading")
    "lf"  '(minimal/open-init-file :wk "Open init.el")
    "ll"  '(load-file :wk "Load file")

    ;; --- M - manuals ---
    "M"   '(:ignore t :wk "manuals")
    "Mc"  '(consult-info :wk "Consult Info")
    "Mm"  '(man :wk "man")
    "Mw"  '(woman :wk "woman")

    ;; --- p - project ---
    "p"   '(:ignore t :wk "project")
    "pf"  '(project-find-file :wk "Find file in project")
    "pF"  '(project-root-find-file :wk "Project root find file")
    "pr"  '(project-find-regexp :wk "Grep in project")
    "pk"  '(project-kill-buffers :wk "Kill project buffers")
    "pp"  '(project-switch-project :wk "Switch project")
    "pd"  '(project-dired :wk "Dired project")
    "ps"  '(project-shell :wk "Shell project")
    "pS"  '(project-async-shell-command :wk "Async command")
    "pc"  '(project-recompile :wk "Project recompile")

    ;; --- q - quit ---
    "q"   '(:ignore t :wk "quit")
    "qc"  '(save-buffers-kill-terminal :wk "Kill client")
    "qd"  '(save-buffers-kill-emacs :wk "Kill daemon")

    ;; --- T - toggles ---
    "T"   '(:ignore t :wk "toggle")
    "Tn"  '(display-line-numbers-mode :wk "Line numbers")
    "Tw"  '(whitespace-mode :wk "Whitespace")
    "Tt"  '(ghostel :wk "Terminal")
    "Tv"  '(eshell :wk "eshell"))

  ;; --- Windows (Neovim's M-* tree) ---
  (general-define-key
   :states '(normal visual motion)
   "M-w" #'evil-window-next
   "M-W" #'evil-window-prev
   "M-h" #'evil-window-left
   "M-j" #'evil-window-down
   "M-k" #'evil-window-up
   "M-l" #'evil-window-right
   "M-H" #'evil-window-move-far-left
   "M-J" #'evil-window-move-very-bottom
   "M-K" #'evil-window-move-very-top
   "M-L" #'evil-window-move-far-right
   "M-p" #'evil-window-mru
   "M-r" #'evil-window-rotate-downwards
   "M-R" #'evil-window-rotate-upwards
   "M-v" #'evil-window-vsplit
   "M-s" #'evil-window-split
   "M-x" #'evil-window-exchange
   "M-z" #'delete-window
   "M-c" #'evil-window-delete
   "M-q" #'evil-window-delete
   "M-n" #'evil-window-new
   "M-o" #'delete-other-windows
   "M-t" #'evil-window-top-left
   "M-b" #'evil-window-bottom-right
   "M-T" #'tab-bar-move-window-to-tab
   "M-f" #'ffap-other-window
   "M-]" #'xref-find-definitions-other-window
   "M-^" #'find-alternate-file-other-window
   "M-d" #'minimal/diagnostic-at-point
   "M-g t" #'tab-bar-switch-to-next-tab
   "M-g T" #'tab-bar-switch-to-prev-tab
   "M-g <tab>" #'tab-bar-switch-to-last-tab
   "M-=" #'balance-windows
   "M-_" #'evil-window-set-height
   "M-|" #'evil-window-set-width
   "M-+" #'evil-window-increase-height
   "M--" #'evil-window-decrease-height
   "M->" #'evil-window-increase-width
   "M-<" #'evil-window-decrease-width
   "M-<left>" #'windmove-left
   "M-<down>" #'windmove-down
   "M-<up>" #'windmove-up
   "M-<right>" #'windmove-right)

  ;; --- Tabs (Neovim's Tab tree) ---
  (general-create-definer minimal-tab-definer
    :states '(normal visual motion)
    :prefix "TAB")

  (minimal-tab-definer
    ""    '(nil :wk "tabs")
    "TAB" '(tab-bar-switch-to-last-tab :wk "Last tab")
    "n"   '(tab-bar-new-tab :wk "New tab")
    "c"   '(tab-bar-close-tab :wk "Close tab")
    "o"   '(tab-bar-close-other-tabs :wk "Close other tabs")
    "h"   '(tab-bar-switch-to-prev-tab :wk "Previous tab")
    "l"   '(tab-bar-switch-to-next-tab :wk "Next tab")
    "d"   '(tab-bar-duplicate-tab :wk "Duplicate tab")
    "r"   '(tab-bar-rename-tab :wk "Rename tab")
    "H"   '(tab-bar-move-tab-backward :wk "Move tab left")
    "L"   '(tab-bar-move-tab :wk "Move tab right")
    "0"   'minimal/tab-select-0
    "1"   'minimal/tab-select-1
    "2"   'minimal/tab-select-2
    "3"   'minimal/tab-select-3
    "4"   'minimal/tab-select-4
    "5"   'minimal/tab-select-5
    "6"   'minimal/tab-select-6
    "7"   'minimal/tab-select-7
    "8"   'minimal/tab-select-8
    "9"   'minimal/tab-select-9)

  ;; --- Motions and text objects (Neovim's plain keys) ---
  (general-define-key
   :states '(normal visual motion)
   "-"    #'dired-jump
   "gd"   #'minimal/goto-definition
   "gD"   #'eglot-find-declaration
   "g/"   #'xref-find-references
   "g."   #'eglot-find-implementation
   "gb"   #'eglot-find-typeDefinition
   "zV"   #'minimal/fold-others
   "gz"   #'evil-goto-last-change
   "gy"   #'minimal/yank-diagnostic
   "q"    #'minimal/quit-or-record-macro
   "[d"   #'flymake-goto-prev-error
   "]d"   #'flymake-goto-next-error
   "[e"   #'minimal/prev-error-diagnostic
   "]e"   #'minimal/next-error-diagnostic
   "[w"   #'minimal/prev-warning-diagnostic
   "]w"   #'minimal/next-warning-diagnostic
   "[i"   #'minimal/prev-note-diagnostic
   "]i"   #'minimal/next-note-diagnostic
   "[h"   #'minimal/prev-note-diagnostic
   "]h"   #'minimal/next-note-diagnostic
   "[g"   #'diff-hl-previous-hunk
   "]g"   #'diff-hl-next-hunk
   "[G"   #'diff-hl-previous-hunk
   "]G"   #'diff-hl-next-hunk
   "[<"   #'smerge-prev
   "]<"   #'smerge-next
   "[>"   #'smerge-prev
   "]>"   #'smerge-next
   "[x"   #'smerge-prev
   "]x"   #'smerge-next
   "[|"   #'smerge-prev
   "]|"   #'smerge-next
   "[m"   #'beginning-of-defun
   "]m"   #'end-of-defun
   "g{"   #'evil-backward-paragraph
   "g}"   #'evil-forward-paragraph
   "gsj"  #'hs-show-block
   "gsk"  #'hs-hide-block
   "gsJ"  #'hs-toggle-hiding
   "gl"   #'align-regexp
   "gL"   #'align-current
   "M-i"  #'minimal/insert-space
   "M-I"  #'minimal/insert-space-line-start
   "M-a"  #'minimal/append-space
   "M-A"  #'minimal/append-space-line-end
   "<F5>"  #'dap-continue
   "<F8>"  #'minimal/dap-repl
   "<F9>"  #'dap-breakpoint-toggle
   "<F10>" #'dap-next
   "<F11>" #'dap-step-in)

  ;; --- Insert state (Neovim's in-insert LSP keys) ---
  (general-define-key
   :states '(insert)
   "C-n" #'minimal/complete-next
   "C-p" #'minimal/complete-prev
   "C-e" #'minimal/complete-dismiss
   "C-s" #'minimal/complete-signature
   "M-a" #'eglot-code-actions)

  ;; --- Multicursor (Neovim's M-m tree) ---
  (general-create-definer minimal-mc-definer
    :states '(normal visual motion)
    :prefix "M-m")

  (minimal-mc-definer
    ""    '(nil :wk "multicursor")
    "n"   '(mc/mark-next-like-this :wk "Mark next")
    "p"   '(mc/mark-previous-like-this :wk "Mark previous")
    "a"   '(mc/mark-all-like-this :wk "Mark all")
    "l"   '(mc/edit-lines :wk "Edit lines")))

(provide 'minimal-keys-modal)

;;; minimal-keys-modal.el ends here
