;; -*- lexical-binding: t; outline-regexp: ";; ---"; eval: (local-set-key (kbd "C-c i") #'consult-outline); -*-

;; A foolish attempt on a minimal EMACS configuration, by @gersonfaneto.

;; --- Straight.el Configuration ---
;; Specify the branch for straight.el.
(setq straight-repository-branch "develop")

;; Bootstrap straight.el if it's not already installed.
(defvar bootstrap-version)

(let ((bootstrap-file
       (expand-file-name
	"straight/repos/straight.el/bootstrap.el"
	(or (bound-and-true-p straight-base-dir)
	    user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
	(url-retrieve-synchronously
	 "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
	 'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Enable use-package and set its behavior.
(straight-use-package 'use-package)

;; Configure straight.el itself.
(use-package straight
  :custom
  (use-package-verbose nil)
  (use-package-always-ensure t)
  (straight-current-profile 'base)
  (straight-use-package-by-default t)
  (straight-vc-git-default-protocol 'ssh)
  :config
  (setq straight-profiles
	`((base . ,(file-name-concat user-emacs-directory "straight.lockfile.default.el"))
	  (programming . ,(file-name-concat user-emacs-directory "straight.lockfile.programming.el")))))

;; Load project.el before packages that bind into `project-prefix-map' or
;; consult `project-switch-commands'.
(require 'project)

;; --- General Settings ---
(use-package emacs
  :straight nil
  :ensure nil
  :bind (:map global-map
	      ("<escape>" . keyboard-escape-quit))
  :bind (:map isearch-mode-map
	      ("<escape>" . keyboard-escape-quit))
  :bind (:map minibuffer-local-map
	      ("<escape>" . keyboard-escape-quit)))

;; --- Server Mode ---
;; Start Emacs server if not already running, for emacsclient.
(use-package server
  :straight nil
  :ensure nil
  :config
  (unless (server-running-p)
    (server-start)))

;; --- Environment ---
(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; --- Editing Enhancements ---
;; Multiple cursors for editing multiple places simultaneously.
(use-package multiple-cursors
  :custom
  (mc/always-run-for-all t)
  :bind
  ("C->" . 'mc/mark-next-like-this)   ;; Mark next similar occurrence
  ("C-<" . 'mc/mark-previous-like-this) ;; Mark previous similar occurrence
  ("C-;" . 'mc/skip-to-next-like-this)  ;; Skip to next similar occurrence
  ("C-:" . 'mc/skip-to-previous-like-this) ;; Skip to previous similar occurrence
  ("C-c C-<" . 'mc/mark-all-like-this)  ;; Mark all similar occurrences
  ("C-S-c C-S-c" . 'mc/edit-lines))     ;; Edit multiple lines

;; Move text up/down.
(use-package move-text
  :bind
  ("M-p" . 'move-text-up)             ;; Move line/region up
  ("M-n" . 'move-text-down))          ;; Move line/region down

;; Expand region for selecting increasingly larger code blocks.
(use-package expand-region
  :bind
  ("C-+" . 'er/expand-region))       ;; Expand region

(delete-selection-mode 1) ;; Deletes text between the point and the mark when a selection is active.

;; --- Core Modules ---
;; Most configuration lives in modules/; init.el wires it up and keeps shared
;; settings.
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))
(require 'minimal-keys)
(require 'minimal-session)
(require 'minimal-ui)
(require 'minimal-completion)

;; --- Feature Modules ---
(require 'minimal-programming)
(require 'minimal-tools)
(require 'minimal-writing)

;; --- Frame Setup ---
;; Function to set up fonts and theme for new frames.
(defun minimal/setup-frame (frame)
  "Setup fonts, theme, and modeline for new frames."
  (with-selected-frame frame
    (frame-set-background-mode frame)	; Apply already-chosen background (do NOT override it)
    (minimal/load-theme)		; Load theme after background mode is correct
    (set-frame-font (format "%s %s" minimal/default-font-family minimal/default-font-size) nil t)
    (when minimal/custom-font-height
      (set-face-attribute 'default frame :height minimal/custom-font-height))))

;; Load local customizations if the file exists.
(if (file-exists-p minimal/local-file)
    (load-file minimal/local-file))

;; Apply frame setup when Emacs starts or when a new frame is created.
(if (daemonp)
    ;; If Emacs is running as a daemon, hook setup to new frames.
    (add-hook 'after-make-frame-functions #'minimal/setup-frame)
  ;; Otherwise, set up the current frame.
  (minimal/setup-frame (selected-frame)))
