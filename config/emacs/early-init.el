;; -*- lexical-binding: t; outline-regexp: ";; ---"; eval: (local-set-key (kbd "C-c i") #'consult-outline); -*-

;; A foolish attempt on a minimal EMACS configuration, by @gersonfaneto.

;; --- XDG Paths ---
;; Configuration lives in the checkout, but packages and state do not.
(defconst minimal/data-dir
  (expand-file-name
   "emacs" (or (getenv "XDG_DATA_HOME") (expand-file-name "~/.local/share")))
  "Directory for persistent Emacs data, such as straight.el.")

(defconst minimal/cache-dir
  (expand-file-name
   "emacs" (or (getenv "XDG_CACHE_HOME") (expand-file-name "~/.cache")))
  "Directory for disposable Emacs data, such as native-compiled files.")

(defconst minimal/state-dir
  (expand-file-name
   "emacs" (or (getenv "XDG_STATE_HOME") (expand-file-name "~/.local/state")))
  "Directory for Emacs state, such as custom-file and session history.")

(defconst minimal/theme-palette-file
  (expand-file-name
   "quickshell/emacs-palette.el"
   (or (getenv "XDG_STATE_HOME") (expand-file-name "~/.local/state")))
  "Palette rendered by the Magi theme pipeline.")

(dolist (dir (list minimal/data-dir minimal/cache-dir minimal/state-dir
                   (expand-file-name "org" minimal/data-dir)
                   (expand-file-name "auto-save" minimal/state-dir)
                   (expand-file-name "auto-save-list" minimal/state-dir)
                   (expand-file-name "backups" minimal/state-dir)))
  (make-directory dir t))

;; straight.el installs its repositories under XDG data and builds under XDG
;; cache, so the live checkout only contains source.
(setq straight-base-dir minimal/data-dir
      straight-build-dir (expand-file-name "straight/build" minimal/cache-dir))

(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" minimal/cache-dir)))

;; --- Startup Optimizations ---
;; Suppress the visual bell for fewer distractions.
(setq ring-bell-function 'ignore)

;; Set minimum warning levels to errors to reduce noise during startup.
(setq warning-minimum-level :error
      warning-minimum-log-level :error)

;; Optimize garbage collection for faster startup by increasing the threshold.
(setq gc-cons-percentage 0.6
      gc-cons-threshold most-positive-fixnum)

;; Adjust garbage collection threshold after initialization is complete.
(add-hook 'after-init-hook
    #'(lambda () (setq gc-cons-threshold (* 8 1024 1024))))

;; Defer package startup until after init.
(setq package-enable-at-startup nil)

;; Disable the startup echo area message if Emacs is not running as a daemon.
(unless (daemonp)
  (advice-add #'display-startup-echo-area-message :override #'ignore))

;; Prevent implied frame resizing during startup.
(setq frame-inhibit-implied-resize t)

;; Disable font cache compaction to potentially speed up startup.
(setq inhibit-compacting-font-caches t)

;; Reduce idle update delay for quicker UI responsiveness.
(setq idle-update-delay 1.0)

;; --- UI Customizations ---
;; Disable the mode line to simplify the interface.
;; (setq mode-line-format nil)

;; Disable the startup screen and initial scratch message for a cleaner start.
(setq inhibit-startup-screen t
      initial-scratch-message nil)

;; Turn off scroll bars, vertical scroll bars, menu bar, tool bar, and tooltips
;; to further minimize the UI.
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode 0))

(when (fboundp 'vertical-scroll-bars)
  (vertical-scroll-bars 0))

(when (fboundp 'menu-bar-mode)
  (menu-bar-mode 0))

(when (fboundp 'tool-bar-mode)
  (tool-bar-mode 0))

(when (fboundp 'tooltip-mode)
  (tooltip-mode 0))

;; --- Buffers Handling and Behavior ---
;; Keep crash recovery and versioned backups, but write them under XDG state.
(setq auto-save-default t
      auto-save-timeout 20
      auto-save-interval 200
      auto-save-file-name-transforms
      `(("\\`/[^/]*:\\([^/]*/\\)*\\([^/]*\\)\\'" "/tmp/\\2" t)
        ("\\`.*\\'" ,(file-name-as-directory (expand-file-name "auto-save" minimal/state-dir)) t))
      auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" minimal/state-dir)
      make-backup-files t
      backup-directory-alist `(("." . ,(expand-file-name "backups" minimal/state-dir)))
      backup-by-copying t
      version-control t
      delete-old-versions t
      kept-old-versions 2
      kept-new-versions 6
      tramp-persistency-file-name (expand-file-name "tramp" minimal/state-dir))

;; Persistent history, places, recent files, and bookmarks.
(setq savehist-file (expand-file-name "history" minimal/state-dir)
      save-place-file (expand-file-name "places" minimal/state-dir)
      recentf-save-file (expand-file-name "recentf" minimal/state-dir)
      bookmark-default-file (expand-file-name "bookmarks" minimal/state-dir))

;; Set default indentation and line wrapping behavior.
(setq tab-width 2
      fill-column 100
      indent-tabs-mode nil)

;; Enable relative line numbers if Emacs version is recent enough.
(when (version<= "26.0.50" emacs-version)
  (setq display-line-numbers-type 'relative)
  (global-display-line-numbers-mode))

(add-hook 'prog-mode-hook
    #'(lambda () (toggle-truncate-lines 1)))

;; --- Editor Interactions ---
;; Disable all interactions through dialogs.
(setq use-dialog-box nil
      use-file-dialog nil)

;; Use short answers for prompts and disable confirmation for certain actions.
(setq use-short-answers t
      compilation-ask-about-save nil
      confirm-nonexistent-file-or-buffer nil)

;; Prevent the `kill-ring' to take empty lines.
(defun minimal/dont-kill-empty-lines-advice (orig-fun string &rest args)
  "Do not call ORIG-FUN if STRING is empty or just whitespace."
  (unless (string-match-p "\\`[[:space:]\n]*\\'" string)
    (apply orig-fun string args)))

(advice-add 'kill-new :around #'minimal/dont-kill-empty-lines-advice)

;; --- Custom File and Theme Definitions ---
;; Define paths and initial settings for custom files, font, and theme.
(setq minimal/local-early-file (expand-file-name "local-early-init.el" minimal/state-dir)
      minimal/local-file (expand-file-name "local.el" minimal/state-dir)
      minimal/org-directory (expand-file-name "org" minimal/data-dir)
      minimal/default-font-family (or (getenv "MAGI_EMACS_FONT") "JetBrainsMono Nerd Font")
      minimal/default-variable-font-family (or (getenv "MAGI_EMACS_VARIABLE_FONT") "Fira Sans")
      minimal/default-font-size (string-to-number (or (getenv "MAGI_EMACS_FONT_SIZE") "10"))
      minimal/default-theme 'minimal)

;; --- Custom File Loading ---
;; Path to the custom file.
(setq minimal/custom-file (expand-file-name "custom.el" minimal/state-dir))

;; Create the custom file if it doesn't exist.
(if (not (file-exists-p minimal/custom-file))
    (make-empty-file minimal/custom-file))

;; Load custom file if it exists.
(when (file-exists-p minimal/custom-file)
  (setq custom-file minimal/custom-file)	;; Set Emacs's custom-file variable
  (load-file custom-file))			;; Load the custom file

;; --- Theme Palette ---
;; The Magi theme pipeline renders the active palette before Emacs starts. Fall
;; back to the local defaults when no palette has been rendered yet.
(defvar minimal-palette nil)
(when (file-exists-p minimal/theme-palette-file)
  (load minimal/theme-palette-file 'noerror 'nomessage))

;; minimal-style is defined in the theme file (loaded later).
;; Set it now so the rendered palette or a fallback is used before frames exist.
(defvar minimal-style 'dark)
(setq frame-background-mode minimal-style)

;; Prevent flashbang: set frame colors before any frame is created.
(let ((bg (or (alist-get 'bg minimal-palette)
              (if (eq minimal-style 'dark) "#0d0d0d" "#ffffff")))
      (fg (or (alist-get 'fg minimal-palette)
              (if (eq minimal-style 'dark) "#e0e0e0" "#000000"))))
  (push (cons 'background-color bg) default-frame-alist)
  (push (cons 'foreground-color fg) default-frame-alist))

;; --- Custom Lisp Loading ---
;; Load custom libraries and modules
(mapc
 (lambda (string)
   (add-to-list 'load-path (locate-user-emacs-file string)))
 '("minimal-lisp" "minimal-modules"))

;; Load custom themes
(mapc
 (lambda (string)
   (add-to-list 'custom-theme-load-path (locate-user-emacs-file string)))
 '("minimal-themes"))

;; --- Private Early Configuration ---
;; Machine-specific overrides that must run before init.el. Keep tracked
;; configuration generic; put local experiments in the state directory.
(when (file-exists-p minimal/local-early-file)
  (load minimal/local-early-file 'noerror 'nomessage))
