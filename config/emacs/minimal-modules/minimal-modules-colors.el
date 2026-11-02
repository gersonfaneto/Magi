(setq custom-safe-themes t)

(defun minimal/clear-previous-themes (&rest _)
  "Clear existing theme settings instead of layering them."
  (mapc #'disable-theme custom-enabled-themes))

(advice-add 'load-theme :before #'minimal/clear-previous-themes)

(defun minimal/load-palette ()
  "Load the palette rendered by the Magi theme pipeline."
  (when (file-exists-p minimal/theme-palette-file)
    (load minimal/theme-palette-file 'noerror 'nomessage)))

(defun minimal/load-theme ()
  "Load the default theme."
  (interactive)
  (setq frame-background-mode minimal-style)
  (mapc #'frame-set-background-mode (frame-list))
  (load-theme minimal/default-theme t)
  (when (bound-and-true-p minimal/custom-font-height)
    (set-face-attribute 'default (selected-frame) :height minimal/custom-font-height)))

(defun minimal/reload-theme ()
  "Reload the Magi palette and reapply the Emacs theme."
  (interactive)
  (minimal/load-palette)
  (minimal/load-theme)
  (redraw-frame))

(defun minimal/run-theme-command (&rest args)
  "Run `magi theme ARGS' asynchronously.
The theme renderer runs this Emacs' reload hook when it is done, so the
call has to return immediately instead of waiting for the child process."
  (unless (executable-find "magi")
    (user-error "magi not found"))
  (apply #'start-process "magi-theme" nil "magi" "theme" args))

(defun minimal/select-scheme ()
  "Prompt for a Magi scheme and apply it to the whole desktop."
  (interactive)
  (unless (executable-find "magi")
    (user-error "magi not found"))
  (let* ((output (shell-command-to-string "magi theme list"))
         (schemes (split-string output "\n" t)))
    (when schemes
      (minimal/run-theme-command
       "set" (completing-read "Scheme: " schemes nil t)))))

(defun minimal/toggle-background ()
  "Toggle the whole desktop between the light and dark tone."
  (interactive)
  (minimal/run-theme-command
   "bg" (if (eq minimal-style 'dark) "light" "dark")))

(global-set-key (kbd "C-c t b") 'minimal/toggle-background)
(global-set-key (kbd "C-c t c") 'minimal/select-scheme)

(provide 'minimal-modules-colors)
