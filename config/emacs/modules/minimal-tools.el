;;; minimal-tools.el --- Files, VCS, terminals, and AI tools -*- lexical-binding: t; -*-

;;; Commentary:
;; Dired, Magit, Git links, direnv, Ghostel, Popper, and GPTel.

;;; Code:

(require 'project)

;; --- Dired ---
(defun +dired/open-with-external-program ()
  "Open the marked file in dired with its default external application.
Uses `xdg-open` to determine the appropriate application."
  (interactive)
  (let ((file (dired-get-file-for-visit)))
    (call-process "xdg-open" nil 0 nil file)))

(defun +dired/create-directory ()
  "Wrapper to `dired-create-directory' to avoid minibuffer completion."
  (interactive)
  (let ((search-term
         (read-from-minibuffer "Dir :: ")))
    (dired-create-directory search-term)))

(defun +dired/create-empty-file ()
  "Wrapper to `dired-create-empty-file' to avoid minibuffer completion."
  (interactive)
  (let ((search-term
         (read-from-minibuffer "File :: ")))
    (dired-create-empty-file search-term)))

(use-package dired
  :straight nil
  :ensure nil
  :defer t
  :hook
  (dired-mode . dired-hide-details-mode)
  :bind (:map dired-mode-map
    ("-" . dired-up-directory)
    ("_" . +dired/create-empty-file)
    ("+" . +dired/create-directory)
    ("," . nil)
    (", ." . dired-omit-mode)
    (", c" . dired-do-copy)
    (", d" . dired-hide-details-mode)
    (", g" . dired-mark-files-containing-regexp)
    (", h" . dired-hide-details-mode)
    (", m" . dired-mark-files-regexp)
    (", n" . dired-create-directory)
    (", o" . +dired/open-with-external-program)
    (", r" . dired-do-rename)
    (", s" . dired-do-shell-command)
    (", u" . dired-unmark-all-marks))
  :custom
  (delete-by-moving-to-trash t)
  (dired-clean-confirm-killing-deleted-buffers nil)
  (dired-create-destination-dirs 'ask)
  (dired-dwim-target t)
  (dired-hide-details-hide-information-lines nil)
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-listing-switches "-lhAX --group-directories-first")
  (dired-make-directory-clickable t)
  (dired-mouse-drag-files t)
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always))

(use-package dired-x
  :after dired
  :straight nil
  :ensure nil
  :hook (dired-mode . dired-omit-mode)
  :config
  (setq dired-omit-files
        (concat dired-omit-files "\\|^\\..+$")))

;; --- Version Control ---
;; Magit for Git integration.
(use-package magit
  :bind
  ("C-c g s" . 'magit-status)
  ("C-c g l" . 'magit-log))

(use-package git-link
  :custom
  (git-link-open-in-browser t)
  :bind
  ("C-c g o" . 'git-link-dispatch))

;; --- Environment ---
;; Direnv for managing environment variables in projects.
(use-package direnv
  :if (executable-find "direnv")
  :config
  (direnv-mode))

;; --- Terminal ---
(use-package ghostel
  :bind
  (("C-x m" . ghostel)
   :map ghostel-semi-char-mode-map
   ("C-s"  . consult-line)
   ("C-k"  . my/ghostel-send-C-k-and-kill)
   ;; ...
   ("M-0" . 'delete-window)
   ("M-1" . 'delete-other-windows)
   ("M-2" . (lambda () (interactive) (minimal/split-window-and-switch t)))
   ("M-3" . (lambda () (interactive) (minimal/split-window-and-switch nil)))
   ("M-4" . 'find-file-other-window)
   ("M-z" . 'minimal/toggle-maximize-buffer)
   ("M-o" . 'other-window)
   ;; I'm used to go up/down the shell history with M-n/p from eshell
   ;; Simulate this behavior in ghostel by sending C-p and C-n
   ("M-p" . (lambda () (interactive) (ghostel-send-key "p" "ctrl")))
   ("M-n" . (lambda () (interactive) (ghostel-send-key "n" "ctrl")))
   :map project-prefix-map
   ("m" . ghostel-project)
   ("M" . ghostel-project-list-buffers))
  :config
  (defun my/ghostel-send-C-k-and-kill ()
    "Send `C-k' to ghostel.
Like normal Emacs `C-k'.  Kill to end of line and put content in kill-ring."
    (interactive)
    (kill-ring-save (point) (line-end-position))
    (ghostel-send-key "k" "ctrl"))

  (add-to-list 'project-switch-commands '(ghostel-project "Ghostel") t)
  (add-to-list 'project-switch-commands '(ghostel-project-list-buffers "Ghostel buffers") t)
  (add-to-list 'ghostel-eval-cmds '("magit-status-setup-buffer" magit-status-setup-buffer)))

(use-package ghostel-eshell
  :straight nil
  :ensure nil
  :hook (eshell-load . ghostel-eshell-visual-command-mode))

(use-package ghostel-compile
  :straight nil
  :ensure nil
  :hook (after-init . ghostel-compile-global-mode))

(use-package ghostel-comint
  :straight nil
  :ensure nil
  :hook (after-init . ghostel-comint-global-mode))

;; --- Popper ---
(use-package popper
  :hook (after-init . popper-mode)
  :bind
  (("M-`"   . popper-toggle)
   ("M-~"   . popper-cycle)
   ("C-M-`" . popper-toggle-type))
  :custom
  (popper-reference-buffers
   '("\\*Messages\\*"
     "Output\\*$"
     "\\*Async Shell Command\\*"
     help-mode
     compilation-mode))
  :config
  (popper-echo-mode 1))

;; --- AI Assistance ---
;; GPTel for interacting with AI models (Gemini).
(use-package gptel
  :commands
  (gptel gptel-send)                  ;; Commands for GPTel
  :config
  ;; Configure GPTel to use Gemini and stream responses.
  (setq gptel-model 'gemini-2.5-flash-lite
	gptel-backend (gptel-make-gemini "Gemini"
			:key (getenv "GEMINI_API_KEY") ;; Ensure GEMINI_API_KEY is set in your environment or Emacs variables
			:stream t))
  :bind (("C-c j" . gptel-menu)        ;; Open GPTel menu
	 ("C-c C-g" . gptel-abort)     ;; Abort current GPTel request
	 ("C-c <return>" . gptel-send)  ;; Send prompt to GPTel
	 ("C-c C-<return>" . gptel-menu))) ;; Send prompt and show menu

(provide 'minimal-tools)

;;; minimal-tools.el ends here
