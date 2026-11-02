;;; minimal-programming.el --- Programming modes and language tooling -*- lexical-binding: t; -*-

;;; Commentary:
;; Parentheses, whitespace, Eglot, and the language majors.

;;; Code:

;; Keep parentheses visible and balanced without third-party packages.
(show-paren-mode 1)
(add-hook 'prog-mode-hook #'electric-pair-local-mode)

;; Delete trailing whitespace before saving in programming buffers. Prose
;; formats keep trailing spaces because they can be significant there.
(defun minimal/enable-delete-trailing-whitespace ()
  "Delete trailing whitespace before saving the current buffer."
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

(add-hook 'prog-mode-hook #'minimal/enable-delete-trailing-whitespace)

;; Jump out of delimiters with TAB in programming modes.
(use-package tab-jump-out
  :hook
  (prog-mode . tab-jump-out-mode))

;; --- Eglot ---
(use-package eglot :straight (:type built-in)
  :custom
  (eglot-autoshutdown t)
  (eglot-sync-connect 0)
  (eglot-max-file-watches 3000)
  (eglot-code-action-indications nil)
  (eglot-report-progress nil)
  (eglot-events-buffer-config '(:size 0 :format short))
  (jsonrpc-event-hook nil)
  :hook (eglot-managed-mode
	 . (lambda ()
	     (setq indent-region-function 'eglot-format)))
  :bind (:map eglot-mode-map
	      ("C-c l r" . eglot-rename)
	      ("C-c l f" . eglot-format-buffer)
	      ("C-c l a" . eglot-code-actions)
	      ("C-c l d" . eglot-find-declaration)
	      ("C-c l D" . eglot-find-typeDefinition)
	      ("C-c l i" . eglot-find-implementation))
  :bind
  ("C-c e r" . eglot-reconnect)
  ("C-c e s" . eglot-shutdown)
  ("C-c e S" . eglot-shutdown-all)
  :config
  (with-eval-after-load 'eglot
    (advice-add 'jsonrpc--log-event :override #'ignore))
  (add-to-list 'eglot-ignored-server-capabilities :inlayHintProvider)
  (add-to-list 'eglot-ignored-server-capabilities :documentHighlightProvider)
  (add-to-list 'eglot-ignored-server-capabilities :codeLensProvider)
  (add-to-list 'eglot-ignored-server-capabilities :documentLinkProvider)
  (add-to-list 'eglot-ignored-server-capabilities :colorProvider)
  (add-to-list 'eglot-ignored-server-capabilities :foldingRangeProvider))

;; --- Lisp ---
(use-package emacs-lisp-mode :straight (:type built-in)
  :mode
  "\\.el\\'"
  :bind
  (("C-c C-j" . eval-print-last-sexp)))

;; --- Markdown Mode ---
(use-package markdown-mode
  :init
  (setq markdown-command "multimarkdown") ;; Set the command for Markdown processing
  :mode
  ("README\\.md\\'" . gfm-mode)       ;; Use GFM mode for README.md files
  :hook
  (markdown-mode . visual-line-mode)
  :bind
  (:map markdown-mode-map
	("C-c C-e" . markdown-do)))     ;; Export Markdown

;; --- Haskell Mode ---
(use-package haskell-mode
  :mode
  "\\.hs\\'"
  :hook
  ((haskell-mode . interactive-haskell-mode)
   (haskell-mode . turn-on-haskell-doc-mode)))

;; --- OCaml Mode ---
(use-package tuareg
  :mode (("\\.ocamlinit\\'" . tuareg-mode)))

(use-package ocaml-eglot
  :after tuareg
  :hook
  (tuareg-mode . ocaml-eglot)
  (ocaml-eglot . eglot-ensure))

;; --- Nix Mode ---
;; Configuration for Nix language files.
(use-package nix-mode
  :mode
  "\\.nix\\'"
  :hook
  (nix-mode . eglot-ensure)
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
		 '((nix-mode) . ("nixd" :initializationOptions
				 (:formatting (:command ["alejandra"])))))))

;; --- Rust Mode ---
(use-package rust-mode
  :hook (rust-mode . eglot-ensure))

;; --- Lua Mode ---
(use-package lua-mode
  :hook
  (lua-mode . eglot-ensure))

(provide 'minimal-programming)

;;; minimal-programming.el ends here
