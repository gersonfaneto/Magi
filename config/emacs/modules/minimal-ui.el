;;; minimal-ui.el --- Themes, modeline, and UI affordances -*- lexical-binding: t; -*-

;;; Commentary:
;; Magi colors, the custom modeline, and which-key.

;;; Code:

;; --- Themes and Appearance ---
;; Use custom colors.
(require 'minimal-modules-colors)

;; Use custom modeline.
(require 'minimal-modules-modeline)

;; --- UI Enhancements ---
;; Enable which-key to show keybindings, with Neovim's timing and layout.
(use-package which-key
  :custom
  (which-key-idle-delay 0.3)
  (which-key-idle-secondary-delay 0.05)
  (which-key-prefix-prefix "+")
  (which-key-separator " ")
  (which-key-max-description-length 40)
  :config
  (which-key-setup-side-window-bottom)
  (which-key-mode))

(provide 'minimal-ui)

;;; minimal-ui.el ends here
