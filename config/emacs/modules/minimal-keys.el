;;; minimal-keys.el --- Global keybindings and small commands -*- lexical-binding: t; -*-

;;; Commentary:
;; Font scaling, window management, buffer commands, and global keys.

;;; Code:

;; --- Font Scaling Functions ---
(defvar minimal/custom-font-height nil
  "Custom `:height' for the `default' face, or nil to use the default font size.")

(defun minimal/scale-font (n)
  "With positive N, increase the font size; with negative N, decrease it; with N=0, reset to default height."
  (setq minimal/custom-font-height
        (cond ((> n 0) (+ (face-attribute 'default :height) 10))
              ((< n 0) (max 10 (- (face-attribute 'default :height) 10)))
              (t nil)))
  (set-face-attribute 'default (selected-frame) :height
                      (or minimal/custom-font-height
                          (* minimal/default-font-size 10))))

;; Define keybindings for font scaling.
(global-set-key (kbd "C-0") (lambda () (interactive) (minimal/scale-font 0))) ;; Reset font size
(global-set-key (kbd "C-=") (lambda () (interactive) (minimal/scale-font 1))) ;; Increase font size
(global-set-key (kbd "C--") (lambda () (interactive) (minimal/scale-font -1))) ;; Decrease font size

;; --- Window Management Keybindings ---
(defun minimal/split-window-and-switch (&optional horizontal)
  "Split window and switch to the new window.
Optional argument HORIZONTAL splits horizontally if non-nil, otherwise vertically."
  (interactive)
  (if horizontal
      (split-window-horizontally)
    (split-window-vertically))
  (other-window 1))

(defun minimal/toggle-maximize-buffer ()
  (interactive)
  (if (and (= 1 (length (window-list)))
	   (assoc ?_ register-alist))
      (jump-to-register ?_)
    (progn
      (window-configuration-to-register ?_)
      (delete-other-windows))))

(global-set-key (kbd "M-0") 'delete-window)
(global-set-key (kbd "M-1") 'delete-other-windows)
(global-set-key (kbd "M-2") (lambda () (interactive) (minimal/split-window-and-switch t)))
(global-set-key (kbd "M-3") (lambda () (interactive) (minimal/split-window-and-switch nil)))
(global-set-key (kbd "M-4") 'find-file-other-window)
(global-set-key (kbd "M-z") 'minimal/toggle-maximize-buffer)
(global-set-key (kbd "M-o") 'other-window)

;; --- Editing and Navigation Keybindings ---
(global-set-key (kbd "M-j") (lambda () (interactive) (duplicate-dwim) (next-line)))

(global-set-key (kbd "M-u") 'upcase-dwim)
(global-set-key (kbd "M-l") 'downcase-dwim)
(global-set-key (kbd "M-c") 'capitalize-dwim)

(global-set-key (kbd "M-g l") 'browse-url)
(global-set-key (kbd "C-c s") 'flyspell-mode)

(defun minimal/backward-kill-word ()
  "Kill whitespace, a word, or a single character before point.
If the character before point is word-constituent, kill the
whole preceding word.  If it is horizontal whitespace, delete
all contiguous whitespace.  Otherwise, delete just the character
before point."
  (interactive)
  (let ((char (char-before)))
    (cond
     ((and char (eq (char-syntax char) ?w))
      (backward-kill-word 1))
     ((and char (memq char '(?\s ?\t)))
      (delete-horizontal-space t))
     (t
      (backward-delete-char 1)))))

(global-set-key (kbd "<C-backspace>") 'minimal/backward-kill-word)

;; --- Buffer Management ---
(defun kill-all-buffers ()
  "Close all buffers."
  (interactive)
  (delete-other-windows) ;; Close all but the active window
  (save-some-buffers)    ;; Prompt to save modified buffers
  (let ((kill-buffer-query-functions '())) ;; Disable confirmation for killing buffers
    (mapc 'kill-buffer (buffer-list))))    ;; Kill all listed buffers

;; Keybindings for buffer navigation and management.
(global-set-key (kbd "C-x C-p") 'previous-buffer)     ;; Previous buffer
(global-set-key (kbd "C-x C-n") 'next-buffer)         ;; Next buffer
(global-set-key (kbd "C-x k") 'kill-current-buffer)   ;; Kill current buffer
(global-set-key (kbd "C-x C-S-k") 'kill-all-buffers)  ;; Kill all buffers

;; --- Compilation Keybindings ---
(global-set-key (kbd "C-c c") 'compile)             ;; Run compilation
(global-set-key (kbd "C-c r") 'recompile)           ;; Recompile project

;; --- General Keybindings ---
(global-set-key (kbd "C-c C-c r") 'restart-emacs)
(global-set-key (kbd "C-c C-c k") 'kill-emacs)

(provide 'minimal-keys)

;;; minimal-keys.el ends here
