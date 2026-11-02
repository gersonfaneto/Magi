(require 'minimal-lisp-common)

(defgroup minimal-icons nil
  "Get characters, icons, and symbols for things."
  :group 'convenience)

(defface minimal-icons-icon
  '((t :inherit (bold fixed-pitch)))
  "Basic attributes for an icon."
  :group 'minimal-icons)

(defface minimal-icons-red
  '((default :inherit minimal-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#aa3232")
    (((class color) (min-colors 88) (background dark))
     :foreground "#f06464")
    (t :foreground "red"))
  "Face for icons."
  :group 'minimal-icons)

(defface minimal-icons-green
  '((default :inherit minimal-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#107010")
    (((class color) (min-colors 88) (background dark))
     :foreground "#33bb33")
    (t :foreground "green"))
  "Face for icons."
  :group 'minimal-icons)

(defface minimal-icons-yellow
  '((default :inherit minimal-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#605000")
    (((class color) (min-colors 88) (background dark))
     :foreground "#e0a055")
    (t :foreground "yellow"))
  "Face for icons."
  :group 'minimal-icons)

(defface minimal-icons-blue
  '((default :inherit minimal-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#223399")
    (((class color) (min-colors 88) (background dark))
     :foreground "#5599ff")
    (t :foreground "blue"))
  "Face for icons."
  :group 'minimal-icons)

(defface minimal-icons-magenta
  '((default :inherit minimal-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#8f2270")
    (((class color) (min-colors 88) (background dark))
     :foreground "#ee70aa")
    (t :foreground "magenta"))
  "Face for icons."
  :group 'minimal-icons)

(defface minimal-icons-cyan
  '((default :inherit minimal-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "#226067")
    (((class color) (min-colors 88) (background dark))
     :foreground "#77b0c0")
    (t :foreground "cyan"))
  "Face for icons."
  :group 'minimal-icons)

(defface minimal-icons-gray
  '((default :inherit minimal-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "gray30")
    (((class color) (min-colors 88) (background dark))
     :foreground "gray70")
    (t :foreground "gray"))
  "Face for icons."
  :group 'minimal-icons)

(defface minimal-icons-faint
  '((default :inherit minimal-icons-icon)
    (((class color) (min-colors 88) (background light))
     :foreground "gray70")
    (((class color) (min-colors 88) (background dark))
     :foreground "gray30")
    (t :foreground "gray"))
  "Face for icons."
  :group 'minimal-icons)

(defvar minimal-icons
  '((dired-mode "|_" minimal-icons-gray)
    (archive-mode "|@" minimal-icons-gray)
    (prog-mode ">Π" minimal-icons-magenta) ; πρόγραμμα
    (text-mode ">Α" minimal-icons-green) ; αλφάβητο
    (comint-mode ">_" minimal-icons-gray)
    (document ">Σ" minimal-icons-red) ; σύγγραμμα
    (audio ">Η" minimal-icons-cyan) ; ήχος
    (image ">Ε" minimal-icons-yellow) ; εικόνα
    (video ">Κ" minimal-icons-blue) ; κίνηση (κινηματογράφος)
    (t ">." minimal-icons-faint))
  "Major modes or concepts and their corresponding icons.
Each element is a cons cell of the form (THING STRING FACE), where THING
is a symbol STRING is one or more characters that represent THING, and
FACE is the face to use for it, where applicable.")

(defun minimal-icons--get (thing)
  "Return `minimal-icons' representation of THING."
  (unless (symbolp thing)
    (error "The thing `%s' is not a symbol" thing))
  (when (string-suffix-p "-mode" (symbol-name thing))
    (while-let ((parent (get thing 'derived-mode-parent)))
      (setq thing parent)))
  (or (alist-get thing minimal-icons)
      (alist-get t minimal-icons)))

(defun minimal-icons-get-icon (thing &optional face)
  "Return propertized icon THING."
  (pcase-let ((`(,icon ,inherent-face) (minimal-icons--get thing)))
    (format "%2s" (propertize icon 'font-lock-face (or face inherent-face)))))

(defun minimal-icons-get-file-icon (file)
  "Return FILE icon and face."
  (cond
   ((null file)
    (minimal-icons-get-icon nil))
   ((string-suffix-p "/" file)
    (minimal-icons-get-icon 'dired-mode))
   ((string-match-p (minimal-common--get-file-type-regexp 'archive) file)
    (minimal-icons-get-icon 'archive-mode))
   ((string-match-p (minimal-common--get-file-type-regexp 'text) file)
    (minimal-icons-get-icon 'text-mode))
   ((string-match-p (minimal-common--get-file-type-regexp 'image) file)
    (minimal-icons-get-icon 'image))
   ((string-match-p (minimal-common--get-file-type-regexp 'audio) file)
    (minimal-icons-get-icon 'audio))
   ((string-match-p (minimal-common--get-file-type-regexp 'video) file)
    (minimal-icons-get-icon 'video))
   ((string-match-p (minimal-common--get-file-type-regexp 'document) file)
    (minimal-icons-get-icon 'document))
   ((string-match-p (minimal-common--get-file-type-regexp 'program) file)
    (minimal-icons-get-icon 'prog-mode))
   (t (minimal-icons-get-icon nil))))

;;;; Icons for Dired

;; Adapted from `nerd-icons-dired'

(defun minimal-icons-dired--add-overlay (pos string)
  "Add overlay to display STRING at POS."
  (let ((overlay (make-overlay (1- pos) pos)))
    (overlay-put overlay 'minimal-icons-overlay t)
    (overlay-put overlay 'evaporate t)
    (overlay-put overlay 'after-string (propertize string 'display string))))

(defun minimal-icons-dired--remove-all-overlays ()
  "Remove all `minimal-icons' overlays."
  (dolist (buffer (buffer-list))
    (when (and (derived-mode-p 'dired-mode) minimal-icons-dired-mode)
      (save-restriction
	(widen)
	(remove-overlays nil nil 'minimal-icons-overlay t)))))

(defun minimal-icons-dired--annotate ()
  "Add icons to all files in the visible region of the buffer."
  (save-excursion
    (goto-char (point-min))
    (while (and (dired-next-line 1) (not (eobp)))
      (when-let* ((file (dired-get-filename nil :no-error))
		  (icon (if (file-directory-p file)
			    (minimal-icons-get-file-icon (concat file "/"))
			  (minimal-icons-get-file-icon file))))
	(if (member file '("." ".."))
	    (minimal-icons-dired--add-overlay (dired-move-to-filename) "  \t")
	  (minimal-icons-dired--add-overlay (dired-move-to-filename) (concat icon "\t")))))))

(defun minimal-icons-dired--refresh ()
  "Update the display of icons of files in a Dired buffer."
  (minimal-icons-dired--remove-all-overlays)
  (save-restriction
    (widen)
    (minimal-icons-dired--annotate)))

(defun minimal-icons-dired--setup ()
  "Set up Dired to display icons."
  (setq-local tab-width 1)
  (minimal-icons-dired--refresh))

;;;###autoload
(define-minor-mode minimal-icons-dired-mode
  "Display icons for Dired entries."
  :global t
  (if minimal-icons-dired-mode
      (progn
	(add-hook 'dired-mode-hook #'minimal-icons-dired--setup)
	(add-hook 'dired-after-readin-hook 'minimal-icons-dired--annotate)
	(advice-add 'wdired-abort-changes :after #'minimal-icons-dired--refresh))
    (minimal-icons-dired--remove-all-overlays)
    (remove-hook 'dired-mode-hook #'minimal-icons-dired--setup)
    (remove-hook 'dired-after-readin-hook 'minimal-icons-dired--annotate)
    (advice-remove 'wdired-abort-changes #'minimal-icons-dired--refresh)))

;;;; Icons for Xref

;; Adapted from `nerd-icons-xref'

(defun minimal-icons-xref--add-overlay (position string)
  "Add overlay at POSITION to display STRING."
  (let ((overlay (make-overlay position (+ position 1))))
    (overlay-put overlay 'minimal-icons-overlay t)
    (overlay-put overlay 'evaporate t)
    (overlay-put overlay 'before-string (propertize string 'display string))))

(defun minimal-icons-xref--add-icons ()
  "Add icons to Xref headings."
  (save-excursion
    (goto-char (point-min))
    (let ((prop))
      (while (setq prop (text-property-search-forward 'xref-group))
	(when-let* ((start (prop-match-beginning prop))
		    (end (prop-match-end prop))
		    (file (string-chop-newline (buffer-substring-no-properties start end)))
		    (icon (minimal-icons-get-file-icon file)))
	  (minimal-icons-xref--add-overlay start (concat icon " ")))))))

;;;###autoload
(define-minor-mode minimal-icons-xref-mode
  "Display icons for Xref headings."
  :global t
  (if minimal-icons-xref-mode
      (add-hook 'xref-after-update-hook #'minimal-icons-xref--add-icons)
    (remove-hook 'xref-after-update-hook #'minimal-icons-xref--add-icons)))

;;;; Icons for Buffer menu

(defun minimal-icons-buffer-menu--add-overlay (position string)
  "Add overlay at POSITION to display STRING."
  (let ((overlay (make-overlay position (+ position 1))))
    (overlay-put overlay 'minimal-icons-overlay t)
    (overlay-put overlay 'evaporate t)
    (overlay-put overlay 'before-string (propertize string 'display string))))

(defun minimal-icons-buffer-menu--add-icons (&rest _)
  "Add icons to `Buffer-menu-mode' entries."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'Buffer-menu-mode)
	(save-excursion
	  (goto-char (point-min))
	  (while-let ((match (text-property-search-forward 'tabulated-list-id))
		      (buffer (prop-match-value match))
		      (mode (with-current-buffer buffer major-mode))
		      (icon (minimal-icons-get-icon mode)))
	    (minimal-icons-buffer-menu--add-overlay (line-beginning-position) (concat icon " "))))))))

;;;###autoload
(define-minor-mode minimal-icons-buffer-menu-mode
  "Display icons for `Buffer-menu-mode' entries."
  :global t
  (if minimal-icons-buffer-menu-mode
      (advice-add #'list-buffers--refresh :after #'minimal-icons-buffer-menu--add-icons)
    (advice-remove #'list-buffers--refresh #'minimal-icons-buffer-menu--add-icons)))

(provide 'minimal-lisp-icons)
