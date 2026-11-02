;;; minimal-session.el --- Session persistence and window state -*- lexical-binding: t; -*-

;;; Commentary:
;; History, places, recent files, bookmarks, auto-revert, persistent undo,
;; save-on-focus-loss, and display rules.

;;; Code:

;; --- Session Persistence and Window State ---
;; Keep minibuffer history, point positions, recent files, and bookmarks.
(use-package savehist
  :straight nil
  :ensure nil
  :init
  (setq savehist-additional-variables
        '(kill-ring
          command-history
          query-replace-history
          file-name-history
          minibuffer-history
          search-ring
          regexp-search-ring
          extended-command-history)
        history-length 250
        kill-ring-max 25)
  (savehist-mode 1))

(use-package saveplace
  :straight nil
  :ensure nil
  :init
  (save-place-mode 1))

(use-package recentf
  :straight nil
  :ensure nil
  :init
  (setq recentf-max-saved-items 100
        recentf-max-menu-items 20)
  (recentf-mode 1)
  :bind
  ("C-c f" . recentf))

(use-package bookmark
  :straight nil
  :ensure nil
  :init
  (setq bookmark-save-flag 1))

(use-package uniquify
  :straight nil
  :ensure nil
  :init
  (require 'uniquify)
  (setq uniquify-buffer-name-style 'reverse
        uniquify-separator ":"))

(use-package autorevert
  :straight nil
  :ensure nil
  :init
  (setq auto-revert-verbose nil)
  (global-auto-revert-mode 1))

;; Keep undo history across sessions, like Neovim's `undofile'.
(use-package undo-fu-session
  :straight (:type git :host codeberg :repo "ideasman42/emacs-undo-fu-session"
                   :protocol https)
  :demand t
  :custom
  (undo-fu-session-directory (expand-file-name "undo-fu-session" minimal/state-dir))
  (undo-fu-session-compression 'gz)
  (undo-fu-session-file-limit 512)
  (undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'"))
  :config
  (undo-fu-session-global-mode 1))

;; --- Saving on Focus Loss ---
;; Save modified file buffers when the frame loses focus, like Neovim's
;; `auto_write' autocmds.
(defun minimal/save-file-buffers ()
  "Save every modified buffer that visits a local file."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (and (buffer-modified-p)
                 buffer-file-name
                 (not (file-remote-p buffer-file-name)))
        (let ((inhibit-message t)
              (message-log-max nil))
          (basic-save-buffer))))))

(add-hook 'focus-out-hook #'minimal/save-file-buffers)

;; Undo and redo window layouts, and make repeatable commands easier to use.
(winner-mode 1)
(repeat-mode 1)
(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

;; Avoid persisting text properties in the kill ring.
(defun minimal/kill-ring-unpropertize ()
  "Remove text properties from `kill-ring' entries."
  (setq kill-ring (mapcar #'substring-no-properties kill-ring)))
(add-hook 'kill-emacs-hook #'minimal/kill-ring-unpropertize)

;; Give transient buffers predictable places instead of letting Emacs choose.
(setq display-buffer-alist
      '(("\\*Help\\*"
         (display-buffer-reuse-window display-buffer-below-selected)
         (window-height . 0.33))
        ("\\*compilation\\*"
         (display-buffer-reuse-window display-buffer-below-selected)
         (window-height . 0.33))
        ("\\*[Ee]shell.*\\*"
         (display-buffer-reuse-window display-buffer-below-selected)
         (window-height . 0.40))
        ("\\*[Gg]hostel.*\\*"
         (display-buffer-reuse-window display-buffer-below-selected)
         (window-height . 0.40))))

(provide 'minimal-session)

;;; minimal-session.el ends here
