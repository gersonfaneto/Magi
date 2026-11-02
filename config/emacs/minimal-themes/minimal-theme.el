;;; minimal-theme.el --- Minimal theme with dark/light variants and optional color -*- lexical-binding: t; -*-

(deftheme minimal
  "A minimal theme with dark/light variants.

Set `minimal-style' to 'dark or 'light before loading.
When `minimal-colorize' is non-nil, red/green/yellow accents
replace the otherwise fully monochrome palette.")

;;; Options

(defgroup minimal nil
  "Minimal theme options."
  :group 'faces)

(defcustom minimal-style 'dark
  "Theme variant: 'dark (near-black bg) or 'light (white bg)."
  :type '(choice (const dark) (const light))
  :group 'minimal)

(defcustom minimal-transparent nil
  "Use transparent background."
  :type 'boolean
  :group 'minimal)

(defcustom minimal-dim-inactive nil
  "Dim inactive windows."
  :type 'boolean
  :group 'minimal)

(defcustom minimal-colorize nil
  "Use subtle color accents instead of full monochrome."
  :type 'boolean
  :group 'minimal)

;;; Palette

(defvar minimal--default-bg "#0d0d0d")

(defun minimal--blend (fg percent &optional bg)
  "Blend FG into BG by PERCENT (0-1)."
  (let ((bg (or bg minimal--default-bg)))
    (if (display-graphic-p)
        (let ((fg-r (string-to-number (substring fg 1 3) 16))
              (fg-g (string-to-number (substring fg 3 5) 16))
              (fg-b (string-to-number (substring fg 5 7) 16))
              (bg-r (string-to-number (substring bg 1 3) 16))
              (bg-g (string-to-number (substring bg 3 5) 16))
              (bg-b (string-to-number (substring bg 5 7) 16)))
          (format "#%02x%02x%02x"
                  (round (+ (* percent fg-r) (* (- 1 percent) bg-r)))
                  (round (+ (* percent fg-g) (* (- 1 percent) bg-g)))
                  (round (+ (* percent fg-b) (* (- 1 percent) bg-b)))))
      fg)))

(defun minimal--palette (key fallback)
  "Return KEY from `minimal-palette', or FALLBACK when it is absent."
  (or (and (boundp 'minimal-palette)
           (alist-get key minimal-palette))
      fallback))

(defmacro minimal--with-palette (&rest body)
  "Evaluate BODY with palette colors bound as variables."
  (declare (indent 0))
  `(let* ((dark (eq minimal-style 'dark))
          (minimal--default-bg (minimal--palette 'bg (if dark "#0d0d0d" "#ffffff")))
          (bg            minimal--default-bg)
          (bg_dark       (minimal--palette 'bg-dark (if dark "#0d0d0d" "#f5f5f5")))
          (bg_highlight  (minimal--palette 'bg-highlight (if dark "#1a1a1a" "#e8e8e8")))
          (fg            (minimal--palette 'fg (if dark "#e0e0e0" "#000000")))
          (fg_dark       (minimal--palette 'fg-dark (if dark "#c8c8c8" "#1a1a1a")))
          (fg_gutter     (minimal--palette 'fg-gutter (if dark "#505050" "#c0c0c0")))
          (comment       (minimal--palette 'comment (if dark "#7a7a7a" "#6e6e6e")))
          (cyan          (minimal--palette 'cyan (if dark "#8a8a8a" "#3e3e3e")))
          (dark3         (minimal--palette 'dark3 (if dark "#606060" "#a0a0a0")))
          (dark5         (minimal--palette 'dark5 (if dark "#909090" "#808080")))
          (blue          (minimal--palette 'blue (if dark "#b8b8b8" "#1a1a1a")))
          (blue0         (minimal--palette 'blue0 (if dark "#2a2a2a" "#b0b0b0")))
          (blue1         (minimal--palette 'blue1 (if dark "#a0a0a0" "#2e2e2e")))
          (blue2         (minimal--palette 'blue2 (if dark "#a0a0a0" "#3a3a3a")))
          (blue5         (minimal--palette 'blue5 (if dark "#888888" "#4a4a4a")))
          (blue6         (minimal--palette 'blue6 (if dark "#9a9a9a" "#3e3e3e")))
          (blue7         (minimal--palette 'blue7 (if dark "#1a1a1a" "#e8e8e8")))
          (green         (minimal--palette
                          'green
                          (if minimal-colorize
                              (if dark "#6ca06c" "#3d8040")
                            (if dark "#9a9a9a" "#3a3a3a"))))
          (green1        (minimal--palette
                          'green1
                          (if minimal-colorize
                              (if dark "#8ab88a" "#4d9a50")
                            (if dark "#a8a8a8" "#2e2e2e"))))
          (magenta       (minimal--palette 'magenta (if dark "#b0b0b0" "#2e2e2e")))
          (magenta2      (minimal--palette 'magenta2 (if dark "#b0b0b0" "#2e2e2e")))
          (orange        (minimal--palette 'orange (if dark "#a0a0a0" "#3a3a3a")))
          (purple        (minimal--palette 'purple (if dark "#c8c8c8" "#000000")))
          (red           (minimal--palette
                          'red
                          (if minimal-colorize
                              (if dark "#cc5c5c" "#b34040")
                            (if dark "#a0a0a0" "#1a1a1a"))))
          (red1          (minimal--palette
                          'red1
                          (if minimal-colorize
                              (if dark "#d47a7a" "#c55a5a")
                            (if dark "#c0c0c0" "#000000"))))
          (teal          (minimal--palette 'teal (if dark "#909090" "#5a5a5a")))
          (yellow        (minimal--palette
                          'yellow
                          (if minimal-colorize
                              (if dark "#d4ac4a" "#a89030")
                            (if dark "#c8c8c8" "#1a1a1a"))))
          (error         (minimal--palette 'error red1))
          (warning       (minimal--palette 'warning yellow))
          (info          (minimal--palette 'info blue2))
          (hint          (minimal--palette 'hint teal))
          (none          (if minimal-transparent 'unspecified bg))
          (subtle_bg     (minimal--palette
                          'subtle-bg
                          (minimal--blend fg (if dark 0.10 0.06) bg)))
          (cursorline_bg (minimal--palette
                          'cursorline-bg
                          (minimal--blend fg (if dark 0.20 0.05) bg)))
          (selection_bg  (minimal--palette
                          'selection-bg
                          (minimal--blend fg (if dark 0.25 0.12) bg)))
          (float_bg      (minimal--palette
                          'float-bg
                          (minimal--blend fg (if dark 0.12 0.04) bg)))
          (visual_bg     (minimal--palette 'visual-bg (minimal--blend blue0 0.4))))
     ,@body))

;;; Faces

(minimal--with-palette

(custom-theme-set-faces
 'minimal

 ;; Core UI
 `(default ((t (:background ,none :foreground ,fg))))
 `(fixed-pitch ((t (:family ,minimal/default-font-family))))
 `(variable-pitch ((t (:family ,minimal/default-variable-font-family))))
 `(cursor ((t (:background ,fg))))
 `(fringe ((t (:background ,bg))))
 `(region ((t (:background ,selection_bg))))
 `(highlight ((t (:background ,subtle_bg))))
 `(hl-line ((t (:background ,cursorline_bg))))
 `(shadow ((t (:foreground ,dark5))))
 `(link ((t (:foreground ,blue :underline t))))
 `(link-visited ((t (:foreground ,blue :underline t))))

 ;; Mode line
 `(mode-line ((t (:background ,bg_dark :foreground ,fg_dark))))
 `(mode-line-inactive ((t (:background ,bg_dark :foreground ,fg_gutter))))
 `(mode-line-highlight ((t (:background ,subtle_bg))))
 `(header-line ((t (:background ,bg_highlight :foreground ,fg_dark))))

 ;; Line numbers
 `(line-number ((t (:background ,bg :foreground ,fg_gutter))))
 `(line-number-current-line ((t (:background ,bg_highlight :foreground ,orange :weight bold))))

 ;; Minibuffer / Echo
 `(minibuffer-prompt ((t (:foreground ,blue))))
 `(echo-area-bold ((t (:weight bold))))
 `(message-delayed ((t (:foreground ,fg_dark))))

 ;; Selection / Search
 `(isearch ((t (:background ,bg_highlight :foreground ,fg :weight bold))))
 `(isearch-fail ((t (:background ,red :foreground ,bg))))
 `(lazy-highlight ((t (:background ,bg_highlight :foreground ,fg))))
 `(query-replace ((t (:inherit isearch))))
 `(match ((t (:background ,bg_highlight :foreground ,fg :weight bold))))

 ;; Visual / Cursor
 `(show-paren-match ((t (:foreground ,orange :weight bold))))
 `(show-paren-mismatch ((t (:foreground ,error :weight bold))))
 `(cursor-line ((t (:background ,cursorline_bg))))

 ;; Whitespace / Non-text
 `(trailing-whitespace ((t (:background ,error))))
 `(whitespace-space ((t (:foreground ,fg_gutter))))
 `(whitespace-tab ((t (:foreground ,fg_gutter))))
 `(whitespace-newline ((t (:foreground ,fg_gutter))))
 `(whitespace-indentation ((t (:foreground ,fg_gutter))))
 `(whitespace-empty ((t (:foreground ,fg_gutter))))
 `(nobreak-space ((t (:foreground ,dark3))))
 `(escape-glyph ((t (:foreground ,dark5))))

 ;; Tabs
 `(tab-bar ((t (:background ,bg_dark :foreground ,fg_gutter))))
 `(tab-bar-tab ((t (:background ,bg :foreground ,fg))))
 `(tab-bar-tab-inactive ((t (:background ,bg_dark :foreground ,fg_gutter))))
 `(tab-line ((t (:background ,bg_dark :foreground ,fg_gutter))))
 `(tab-line-tab ((t (:background ,bg :foreground ,blue))))
 `(tab-line-tab-inactive ((t (:background ,bg_dark :foreground ,fg_gutter))))

 ;; Popup / Completion
 `(tooltip ((t (:background ,float_bg :foreground ,fg))))
 `(child-frame-border ((t (:foreground ,blue1))))
 `(internal-border ((t (:background ,bg))))
 `(completions-annotations ((t (:foreground ,comment))))
 `(completions-common-part ((t (:foreground ,blue1))))
 `(completions-first-difference ((t (:foreground ,orange :weight bold))))
 `(completion-preview ((t (:background ,bg_highlight :foreground ,comment))))
 `(completion-preview-exact ((t (:background ,bg_highlight :foreground ,blue1 :weight bold))))

 ;; Vertico
 `(vertico-current ((t (:background ,subtle_bg :weight bold))))
 `(vertico-group-title ((t (:foreground ,comment))))
 `(vertico-multiline ((t (:foreground ,comment))))

 ;; Marginalia
 `(marginalia-documentation ((t (:foreground ,comment))))
 `(marginalia-file-name ((t (:foreground ,green1))))
 `(marginalia-number ((t (:foreground ,orange))))
 `(marginalia-string ((t (:foreground ,green))))

 ;; Diff
 `(diff-added ((t (:foreground ,green :background ,(minimal--blend green 0.25)))))
 `(diff-removed ((t (:foreground ,red :background ,(minimal--blend red 0.25)))))
 `(diff-changed ((t (:foreground ,yellow :background ,(minimal--blend blue7 0.15)))))
 `(diff-refine-added ((t (:foreground ,green1 :weight bold))))
 `(diff-refine-removed ((t (:foreground ,red1 :weight bold))))
 `(diff-header ((t (:foreground ,blue))))
 `(diff-file-header ((t (:foreground ,blue :weight bold))))
 `(diff-hunk-header ((t (:foreground ,comment))))
 `(diff-indicator-added ((t (:foreground ,green :weight bold))))
 `(diff-indicator-removed ((t (:foreground ,red :weight bold))))

 ;; Magit
 `(magit-section-heading ((t (:foreground ,yellow :weight bold))))
 `(magit-section-highlight ((t (:background ,bg_highlight))))
 `(magit-branch-local ((t (:foreground ,green1))))
 `(magit-branch-remote ((t (:foreground ,blue))))
 `(magit-tag ((t (:foreground ,yellow))))
 `(magit-hash ((t (:foreground ,comment))))
 `(magit-filename ((t (:foreground ,fg))))
 `(magit-diff-added ((t (:foreground ,green :background ,(minimal--blend green 0.15)))))
 `(magit-diff-removed ((t (:foreground ,red :background ,(minimal--blend red 0.15)))))
 `(magit-diff-heading ((t (:foreground ,blue :weight bold))))
 `(magit-diff-hunk-heading ((t (:foreground ,comment :background ,bg_highlight))))
 `(magit-diff-context ((t (:foreground ,fg))))
 `(magit-diff-file-heading ((t (:foreground ,fg :weight bold))))
 `(magit-diffstat-added ((t (:foreground ,green))))
 `(magit-diffstat-removed ((t (:foreground ,red))))
 `(magit-refname ((t (:foreground ,comment))))
 `(magit-log-author ((t (:foreground ,blue))))
 `(magit-log-date ((t (:foreground ,comment))))
 `(magit-log-graph ((t (:foreground ,comment))))
 `(magit-process-ok ((t (:foreground ,green))))
 `(magit-process-ng ((t (:foreground ,red))))
 `(magit-blame-heading ((t (:background ,bg_highlight :foreground ,comment))))
 `(magit-blame-hash ((t (:foreground ,comment))))
 `(magit-blame-name ((t (:foreground ,blue))))
 `(magit-blame-date ((t (:foreground ,comment))))
 `(magit-blame-summary ((t (:foreground ,fg))))

 ;; Gitsigns / Git gutter
 `(git-gutter:added ((t (:foreground ,green :weight bold))))
 `(git-gutter:deleted ((t (:foreground ,red :weight bold))))
 `(git-gutter:modified ((t (:foreground ,yellow :weight bold))))

 ;; Dired
 `(dired-directory ((t (:foreground ,blue :weight bold))))
 `(dired-flagged ((t (:foreground ,red :weight bold))))
 `(dired-symlink ((t (:foreground ,cyan))))
 `(dired-mark ((t (:foreground ,yellow :weight bold))))
 `(dired-marked ((t (:foreground ,yellow :weight bold))))
 `(dired-subtree-depth-1-face ((t (:foreground ,fg))))
 `(dired-subtree-depth-2-face ((t (:foreground ,fg))))
 `(dired-subtree-depth-3-face ((t (:foreground ,fg))))

 ;; Which-key
 `(which-key-key-face ((t (:foreground ,blue1))))
 `(which-key-group-description-face ((t (:foreground ,purple))))
 `(which-key-command-description-face ((t (:foreground ,fg))))
 `(which-key-local-map-description-face ((t (:foreground ,green))))
 `(which-key-separator-face ((t (:foreground ,comment))))
 `(which-key-note-face ((t (:foreground ,comment))))

 ;; Flymake
 `(flymake-error ((t (:underline (:style wave :color ,error)))))
 `(flymake-warning ((t (:underline (:style wave :color ,warning)))))
 `(flymake-note ((t (:underline (:style wave :color ,info)))))

 ;; Eglot / LSP
 `(eglot-mode-line ((t (:foreground ,comment))))
 `(eglot-inlay-hint ((t (:foreground ,comment :background ,(minimal--blend comment 0.1)))))
 `(lsp-face-highlight-textual ((t (:background ,bg_highlight))))
 `(lsp-face-highlight-read ((t (:background ,bg_highlight))))
 `(lsp-face-highlight-write ((t (:background ,bg_highlight :weight bold))))
 `(lsp-ui-doc-background ((t (:background ,bg_dark))))
 `(lsp-ui-doc-header ((t (:background ,bg_highlight))))
 `(lsp-ui-peek-header ((t (:background ,bg_highlight :foreground ,yellow))))
 `(lsp-ui-peek-selection ((t (:background ,bg_highlight :weight bold))))
 `(lsp-ui-peek-line-number ((t (:foreground ,comment))))
 `(lsp-ui-sideline-code-action ((t (:foreground ,yellow))))

 ;; Eldoc
 `(eldoc-highlight-function-argument ((t (:foreground ,orange :weight bold))))

 ;; Syntax (font-lock)
 `(font-lock-builtin-face        ((t (:foreground ,purple :weight bold))))
 `(font-lock-comment-face        ((t (:foreground ,comment :slant italic))))
 `(font-lock-comment-delimiter-face ((t (:foreground ,comment :slant italic))))
 `(font-lock-constant-face       ((t (:foreground ,purple))))
 `(font-lock-doc-face            ((t (:foreground ,comment))))
 `(font-lock-doc-markup-face     ((t (:foreground ,comment))))
 `(font-lock-function-name-face  ((t (:foreground ,fg :weight bold))))
 `(font-lock-keyword-face        ((t (:foreground ,purple :weight bold))))
 `(font-lock-negation-char-face  ((t (:foreground ,orange))))
 `(font-lock-number-face         ((t (:foreground ,orange))))
 `(font-lock-operator-face       ((t (:foreground ,blue5))))
 `(font-lock-preprocessor-face   ((t (:foreground ,cyan))))
 `(font-lock-property-face       ((t (:foreground ,green1))))
 `(font-lock-punctuation-face    ((t (:foreground ,blue5))))
 `(font-lock-regexp-grouping-backslash ((t (:foreground ,purple))))
 `(font-lock-regexp-grouping-construct ((t (:foreground ,purple))))
 `(font-lock-string-face         ((t (:foreground ,green))))
 `(font-lock-type-face           ((t (:foreground ,yellow :weight bold))))
 `(font-lock-variable-name-face  ((t (:foreground ,magenta2))))
 `(font-lock-warning-face        ((t (:foreground ,warning :weight bold))))

 ;; Tree-sitter (Emacs 29+)
 `(treesit-face-annotation       ((t (:inherit font-lock-preprocessor-face))))
 `(treesit-face-attribute        ((t (:inherit font-lock-property-face))))
 `(treesit-face-builtin          ((t (:inherit font-lock-builtin-face))))
 `(treesit-face-comment          ((t (:inherit font-lock-comment-face))))
 `(treesit-face-constant         ((t (:inherit font-lock-constant-face))))
 `(treesit-face-constructor      ((t (:foreground ,magenta))))
 `(treesit-face-documentation    ((t (:inherit font-lock-doc-face))))
 `(treesit-face-escape           ((t (:foreground ,magenta))))
 `(treesit-face-function         ((t (:inherit font-lock-function-name-face))))
 `(treesit-face-keyword          ((t (:inherit font-lock-keyword-face))))
 `(treesit-face-label            ((t (:foreground ,blue))))
 `(treesit-face-macro            ((t (:inherit font-lock-preprocessor-face))))
 `(treesit-face-module           ((t (:inherit font-lock-preprocessor-face))))
 `(treesit-face-number           ((t (:inherit font-lock-number-face))))
 `(treesit-face-operator         ((t (:inherit font-lock-operator-face))))
 `(treesit-face-property         ((t (:inherit font-lock-property-face))))
 `(treesit-face-punctuation      ((t (:inherit font-lock-punctuation-face))))
 `(treesit-face-string           ((t (:inherit font-lock-string-face))))
 `(treesit-face-type             ((t (:inherit font-lock-type-face))))
 `(treesit-face-variable         ((t (:inherit font-lock-variable-name-face))))
 `(treesit-face-variable-builtin ((t (:foreground ,magenta2))))

 ;; Org mode
 `(org-document-title ((t (:foreground ,yellow :weight bold :height 1.4))))
 `(org-document-info ((t (:foreground ,blue))))
 `(org-document-info-keyword ((t (:foreground ,comment))))
 `(org-level-1 ((t (:foreground ,fg :weight bold :height 1.2))))
 `(org-level-2 ((t (:foreground ,blue :weight bold :height 1.15))))
 `(org-level-3 ((t (:foreground ,purple :weight bold))))
 `(org-level-4 ((t (:foreground ,green1))))
 `(org-level-5 ((t (:foreground ,magenta))))
 `(org-level-6 ((t (:foreground ,blue))))
 `(org-level-7 ((t (:foreground ,teal))))
 `(org-level-8 ((t (:foreground ,green))))
 `(org-block ((t (:background ,bg_highlight :extend t))))
 `(org-block-begin-line ((t (:foreground ,comment :background ,bg_highlight))))
 `(org-block-end-line ((t (:foreground ,comment :background ,bg_highlight))))
 `(org-code ((t (:foreground ,teal))))
 `(org-verbatim ((t (:foreground ,green1))))
 `(org-quote ((t (:slant italic :background ,bg_highlight))))
 `(org-table ((t (:foreground ,blue))))
 `(org-formula ((t (:foreground ,orange))))
 `(org-checkbox ((t (:foreground ,green :weight bold))))
 `(org-checkbox-statistics-todo ((t (:foreground ,red :weight bold))))
 `(org-checkbox-statistics-done ((t (:foreground ,green :weight bold))))
 `(org-todo ((t (:foreground ,red :weight bold))))
 `(org-done ((t (:foreground ,green :weight bold))))
 `(org-headline-done ((t (:foreground ,comment))))
 `(org-headline-todo ((t (:foreground ,red))))
 `(org-date ((t (:foreground ,blue))))
 `(org-time-grid ((t (:foreground ,comment))))
 `(org-tag ((t (:foreground ,comment :weight bold))))
 `(org-link ((t (:foreground ,blue :underline t))))
 `(org-priority ((t (:foreground ,orange :weight bold))))
 `(org-scheduled ((t (:foreground ,green))))
 `(org-scheduled-previously ((t (:foreground ,warning))))
 `(org-scheduled-today ((t (:foreground ,fg))))
 `(org-sexp-date ((t (:foreground ,blue))))
 `(org-special-keyword ((t (:foreground ,comment))))
 `(org-drawer ((t (:foreground ,comment))))
 `(org-property-value ((t (:foreground ,green1))))
 `(org-meta-line ((t (:foreground ,comment))))
 `(org-archived ((t (:foreground ,comment))))
 `(org-footnote ((t (:foreground ,blue))))
 `(org-indent ((t (:foreground ,bg))))

 ;; Markdown
 `(markdown-header-face ((t (:foreground ,fg :weight bold))))
 `(markdown-header-face-1 ((t (:foreground ,fg :weight bold :height 1.2))))
 `(markdown-header-face-2 ((t (:foreground ,blue :weight bold :height 1.15))))
 `(markdown-header-face-3 ((t (:foreground ,purple :weight bold))))
 `(markdown-header-face-4 ((t (:foreground ,green1))))
 `(markdown-header-face-5 ((t (:foreground ,magenta))))
 `(markdown-header-face-6 ((t (:foreground ,teal))))
 `(markdown-code-face ((t (:background ,bg_highlight))))
 `(markdown-inline-code-face ((t (:foreground ,teal))))
 `(markdown-italic-face ((t (:slant italic))))
 `(markdown-bold-face ((t (:weight bold))))
 `(markdown-strike-through-face ((t (:strike-through t))))
 `(markdown-link-face ((t (:foreground ,blue :underline t))))
 `(markdown-markup-face ((t (:foreground ,comment))))
 `(markdown-url-face ((t (:foreground ,teal))))
 `(markdown-reference-face ((t (:foreground ,blue))))
 `(markdown-list-face ((t (:foreground ,blue5))))
 `(markdown-blockquote-face ((t (:foreground ,comment :slant italic))))
 `(markdown-pre-face ((t (:background ,bg_highlight))))
 `(markdown-language-keyword-face ((t (:foreground ,comment))))
 `(markdown-math-face ((t (:foreground ,purple))))
 `(markdown-metadata-key-face ((t (:foreground ,comment))))
 `(markdown-metadata-value-face ((t (:foreground ,green))))

 ;; Message / Notifications
 `(message-header-name ((t (:foreground ,comment))))
 `(message-header-subject ((t (:foreground ,blue :weight bold))))
 `(message-header-to ((t (:foreground ,fg))))
 `(message-header-cc ((t (:foreground ,fg))))
 `(message-header-other ((t (:foreground ,green1))))
 `(message-header-newsgroups ((t (:foreground ,yellow))))
 `(message-separator ((t (:foreground ,comment :weight bold))))
 `(message-cited-text ((t (:foreground ,comment))))
 `(message-mml ((t (:foreground ,green))))

 ;; LaTeX / AUCTeX
 `(font-latex-sectioning-5-face ((t (:foreground ,yellow :weight bold))))
 `(font-latex-string-face ((t (:foreground ,green))))
 `(font-latex-keyword-face ((t (:foreground ,purple :weight bold))))
 `(font-latex-math-face ((t (:foreground ,blue))))
 `(font-latex-script-char-face ((t (:foreground ,purple))))
 `(font-latex-warning-face ((t (:foreground ,warning :weight bold))))
 `(font-latex-verbatim-face ((t (:foreground ,teal :background ,bg_highlight))))
 `(font-latex-slide-title-face ((t (:foreground ,yellow :weight bold :height 1.2))))

 ;; Eshell / Shell
 `(eshell-prompt ((t (:foreground ,blue :weight bold))))
 `(eshell-ls-directory ((t (:foreground ,blue :weight bold))))
 `(eshell-ls-symlink ((t (:foreground ,cyan))))
 `(eshell-ls-executable ((t (:foreground ,green))))
 `(eshell-ls-readonly ((t (:foreground ,red))))
 `(eshell-ls-unreadable ((t (:foreground ,comment))))
 `(eshell-ls-missing ((t (:foreground ,error))))
 `(eshell-ls-product ((t (:foreground ,orange))))
 `(eshell-ls-archive ((t (:foreground ,magenta))))
 `(eshell-ls-backup ((t (:foreground ,yellow))))

 ;; Compilation
 `(compilation-info ((t (:foreground ,info))))
 `(compilation-warning ((t (:foreground ,warning :weight bold))))
 `(compilation-error ((t (:foreground ,error :weight bold))))
 `(compilation-mode-line-exit ((t (:foreground ,green :weight bold))))
 `(compilation-mode-line-fail ((t (:foreground ,error :weight bold))))
 `(compilation-mode-line-run ((t (:foreground ,warning :weight bold))))
 `(compilation-line-number ((t (:foreground ,comment))))
 `(compilation-column-number ((t (:foreground ,comment))))

 ;; Debugger
 `(debug-warning ((t (:foreground ,warning :weight bold))))
 `(debug-error ((t (:foreground ,error :weight bold))))
 `(debug-info ((t (:foreground ,info))))

 ;; Widget / Button
 `(widget-button ((t (:foreground ,blue :weight bold))))
 `(widget-button-pressed ((t (:foreground ,red))))
 `(widget-documentation ((t (:foreground ,green1))))
 `(widget-field ((t (:background ,bg_highlight :foreground ,fg))))

 ;; Custom
 `(custom-variable-tag ((t (:foreground ,blue))))
 `(custom-group-tag ((t (:foreground ,yellow))))
 `(custom-state ((t (:foreground ,green))))

 ;; Info
 `(info-header-xref ((t (:foreground ,blue :underline t))))
 `(info-menu-star ((t (:foreground ,red))))
 `(info-node ((t (:foreground ,blue :weight bold))))
 `(info-title-1 ((t (:foreground ,fg :weight bold :height 1.2))))
 `(info-title-2 ((t (:foreground ,blue :weight bold :height 1.15))))
 `(info-title-3 ((t (:foreground ,purple :weight bold))))
 `(info-title-4 ((t (:foreground ,green1 :weight bold))))

 ;; Help
 `(help-key-binding ((t (:background ,bg_highlight :foreground ,orange :weight bold))))
 `(help-argument-name ((t (:foreground ,yellow :slant italic))))
 `(help-for-help-header ((t (:foreground ,fg :weight bold :height 1.2))))

 ;; Speedbar / SIDEBAR
 `(speedbar-button-face ((t (:foreground ,green1))))
 `(speedbar-directory-face ((t (:foreground ,blue :weight bold))))
 `(speedbar-file-face ((t (:foreground ,fg))))
 `(speedbar-highlight-face ((t (:background ,subtle_bg))))
 `(speedbar-selected-face ((t (:foreground ,yellow :weight bold))))
 `(speedbar-tag-face ((t (:foreground ,green1))))

 ;; Buttons
 `(button ((t (:foreground ,blue :underline t))))

 ;; Error / Success
 `(error ((t (:foreground ,error :weight bold))))
 `(success ((t (:foreground ,green :weight bold))))
 `(warning ((t (:foreground ,warning :weight bold))))

 ;; Bold / Italic
 `(bold ((t (:weight bold))))
 `(italic ((t (:slant italic))))
 `(bold-italic ((t (:weight bold :slant italic))))
 `(underline ((t (:underline t))))

 ;; Secondary / Tool bar
 `(secondary-selection ((t (:background ,subtle_bg))))
 `(tool-bar ((t (:background ,bg_dark :foreground ,fg_gutter))))
 `(menu ((t (:background ,bg :foreground ,fg))))
 `(scroll-bar ((t (:background ,bg_highlight :foreground ,fg_gutter))))
 `(border ((t (:foreground ,bg))))
 `(separator ((t (:foreground ,comment))))

 ;; Avy / Ace-window
 `(avy-background-face ((t (:foreground ,comment :background ,bg))))
 `(avy-lead-face ((t (:background ,orange :foreground ,bg :weight bold))))
 `(avy-lead-face-0 ((t (:background ,blue :foreground ,bg :weight bold))))
 `(avy-lead-face-1 ((t (:background ,purple :foreground ,bg :weight bold))))
 `(avy-lead-face-2 ((t (:background ,green :foreground ,bg :weight bold))))
 `(ace-window-highlight-method ((t (:background ,orange :foreground ,bg :weight bold))))

 ;; Which-function
 `(which-func ((t (:foreground ,fg :weight bold))))

 ;; Pulse / Highlight
 `(pulse-highlight-start ((t (:background ,selection_bg))))
 `(pulse-highlight-face ((t (:background ,selection_bg))))

 ;; Parenthes
 `(paren-face ((t (:foreground ,blue5 :weight normal))))

 ;; Rainbow delimiters
 `(rainbow-delimiters-depth-1-face ((t (:foreground ,blue))))
 `(rainbow-delimiters-depth-2-face ((t (:foreground ,yellow))))
 `(rainbow-delimiters-depth-3-face ((t (:foreground ,green))))
 `(rainbow-delimiters-depth-4-face ((t (:foreground ,teal))))
 `(rainbow-delimiters-depth-5-face ((t (:foreground ,magenta))))
 `(rainbow-delimiters-depth-6-face ((t (:foreground ,purple))))
 `(rainbow-delimiters-depth-7-face ((t (:foreground ,orange))))
 `(rainbow-delimiters-depth-8-face ((t (:foreground ,red))))
 `(rainbow-delimiters-unmatched-face ((t (:foreground ,error :weight bold))))

 ;; Highlight-indent-guides
 `(highlight-indent-guides-character-face ((t (:foreground ,fg_gutter))))
 `(highlight-indent-guides-stack-character-face ((t (:foreground ,comment))))
 `(highlight-indent-guides-stack-odd-face ((t (:foreground ,comment))))
 `(highlight-indent-guides-stack-even-face ((t (:foreground ,comment))))

 ;; Indent bars / indent-blankline
 `(indent-blankline-face ((t (:foreground ,fg_gutter))))
 `(indent-blankline-context-face ((t (:foreground ,comment))))

 ;; Hydra / Transient
 `(hydra-face-blue ((t (:foreground ,blue))))
 `(hydra-face-red ((t (:foreground ,red))))
 `(hydra-face-amaranth ((t (:foreground ,magenta))))
 `(hydra-face-teal ((t (:foreground ,teal))))
 `(hydra-face-pink ((t (:foreground ,magenta))))
 `(hydra-face-color ((t (:foreground ,yellow))))

 ;; Evil
 `(evil-ex-commands ((t (:foreground ,purple))))
 `(evil-ex-lazy-highlight ((t (:foreground ,orange :weight bold))))
 `(evil-ex-info ((t (:foreground ,blue))))
 `(evil-ex-search ((t (:foreground ,orange :weight bold))))
 `(evil-ex-substitute-matches ((t (:background ,red :foreground ,bg))))
 )
)

;;; Theme registration

(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory
                (file-name-directory load-file-name))))

(provide-theme 'minimal)

;;; minimal-theme.el ends here
