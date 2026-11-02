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
;; Enable which-key to show keybindings.
(use-package which-key
  :config
  (which-key-mode))

(provide 'minimal-ui)

;;; minimal-ui.el ends here
