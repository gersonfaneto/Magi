;;; minimal-completion.el --- Minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;;; Commentary:
;; Vertico, Marginalia, Orderless, Consult, and completion previews.

;;; Code:

;; `minimal/select-scheme' comes from the colors module.
(require 'minimal-modules-colors)

;; --- Completion UI ---
;; Configure Vertico for improved completion UI.
(use-package vertico
  :init
  (vertico-mode)                       ;; Enable Vertico mode
  :custom
  (vertico-count 8)                    ;; Number of items to display
  (vertico-cycle t)                    ;; Cycle through completions
  (vertico-resize t)                   ;; Resize Vertico buffer
  (vertico-scroll-margin 0)            ;; Margin for scrolling
  :config
  ;; Case-insensitive completion for various prompts.
  (setq completion-ignore-case t
	read-buffer-completion-ignore-case t
	read-file-name-completion-ignore-case t))

;; Enable marginalia for annotations in the minibuffer.
(use-package marginalia
  :init
  (marginalia-mode))

;; Configure orderless for advanced completion styles.
(use-package orderless
  :config
  (setq completion-styles '(orderless basic) ;; Use orderless and basic styles
	read-buffer-completion-ignore-case t
	completion-category-defaults nil
	completion-category-overrides '((file (styles partial-completion))))) ;; File completion optimization

;; --- Consult Package ---
;; Enhance search and navigation with Consult.
(use-package consult
  :config
  (defun minimal/select-font--snapshot ()
    "Return the `buffer-face-mode' state of every live buffer."
    (mapcar (lambda (buf)
              (list buf
                    (buffer-local-value 'buffer-face-mode-face buf)
                    (buffer-local-value 'buffer-face-mode buf)))
            (buffer-list)))

  (defun minimal/select-font--restore (snapshot)
    "Restore buffer face overrides recorded in SNAPSHOT."
    (dolist (entry snapshot)
      (when (buffer-live-p (car entry))
        (with-current-buffer (car entry)
          (when (or (nth 1 entry) (nth 2 entry))
            (setq buffer-face-mode-face (nth 1 entry))
            (buffer-face-mode (if (nth 2 entry) 1 -1)))))))

  (defun minimal/select-font--set-global (family)
    "Use FAMILY for every buffer and for frames created later."
    (dolist (entry (minimal/select-font--snapshot))
      (when (and (buffer-live-p (car entry)) (nth 2 entry))
        (with-current-buffer (car entry)
          (buffer-face-mode -1))))
    (set-face-attribute 'default nil :family family)
    (setq minimal/default-font-family family))

  (defun minimal/select-font (&optional arg)
    "Pick a font family for the current buffer, with live preview.
With prefix ARG, change the font for the whole session instead:
per-buffer font overrides are dropped, the `default' face uses the
chosen family, and new frames inherit it."
    (interactive "P")
    (let* ((global (and arg t))
           (buf (current-buffer))
           (orig-face (buffer-local-value 'buffer-face-mode-face buf))
           (orig-mode (buffer-local-value 'buffer-face-mode buf))
           (orig-family (face-attribute 'default :family))
           (orig-font-var minimal/default-font-family)
           (snapshot (when global (minimal/select-font--snapshot)))
           (apply-font
            (lambda (family)
              (if global
                  (minimal/select-font--set-global family)
                (with-current-buffer buf
                  (setq buffer-face-mode-face (list :family family))
                  (buffer-face-mode 1)))))
           (restore
            (lambda ()
              (if global
                  (progn
                    (minimal/select-font--restore snapshot)
                    (set-face-attribute 'default nil :family orig-family)
                    (setq minimal/default-font-family orig-font-var))
                (with-current-buffer buf
                  (setq buffer-face-mode-face orig-face)
                  (buffer-face-mode (if orig-mode 1 -1)))))))
      (let ((selected
             (consult--read
              (font-family-list)
              :prompt (format "Font for %s: "
                              (if global "whole session" (buffer-name buf)))
              :require-match t
              :sort t
              :preview-key 'any
              :default (if global orig-family (plist-get orig-face :family))
              :state (lambda (action cand)
                       (when (or global (buffer-live-p buf))
                         (pcase action
                           ('preview
                            (if cand
                                (funcall apply-font cand)
                              (funcall restore)))))))))
        (if selected
            (funcall apply-font selected)
          (funcall restore)))))
  :bind
   (("C-c C-x b" . 'consult-buffer)      ;; List and switch buffers
    ("C-c C-x m" . 'consult-man)         ;; Search man pages
    ("C-c C-x g" . 'consult-ripgrep)     ;; Search project with ripgrep
    ("C-c C-x s" . 'consult-line)        ;; Search lines across buffers
    ("C-c C-x S" . 'consult-keep-lines)  ;; Keep only selected lines
    ("C-c C-x i" . 'consult-imenu)       ;; Navigate code symbols
    ("C-c C-x t" . 'minimal/select-scheme)  ;; Switch Magi schemes
    ("C-c C-x f" . 'minimal/select-font)))

;; --- Completion-at-Point ---
;; Built-in in-buffer completion preview.
(use-package completion-preview
  :straight nil
  :ensure nil
  :demand t
  ;; :hook
  ;; (prog-mode . completion-preview-mode) ;; Enable previews in programming modes
  :bind
  (:map completion-preview-active-mode-map
    ("M-i" . completion-preview-insert-word)
    ("M-n" . completion-preview-next-candidate)
    ("M-p" . completion-preview-prev-candidate)
    ("M-<return>" . completion-preview-insert)
    ;; With TAB we effectively defer to the *Completions* buffer to
    ;; show more completion candidates at once.
    ("<tab>" . completion-preview-complete))
  :config
  (setq completion-preview-minimum-symbol-length 2)
  (with-eval-after-load 'org
    (add-to-list 'completion-preview-commands #'org-self-insert-command))
  (global-completion-preview-mode 1))

(provide 'minimal-completion)

;;; minimal-completion.el ends here
