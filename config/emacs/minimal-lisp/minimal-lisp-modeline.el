(require 'minimal-lisp-common)
(require 'minimal-lisp-icons)

(defgroup minimal-modeline nil
  "Custom modeline that is stylistically close to the default."
  :group 'mode-line)

(defgroup minimal-modeline-faces nil
  "Faces for my custom modeline."
  :group 'minimal-modeline)

(defcustom minimal-modeline-string-truncate-length 9
  "String length after which truncation should be done in small windows."
  :type 'natnum)

;;;; Faces

(defface minimal-modeline-indicator-button nil
  "Generic face used for indicators that have a background.
Modify this face to, for example, add a :box attribute to all
relevant indicators (combines nicely with my `spacious-padding'
package).")

(defface minimal-modeline-indicator-small
  '((t :height 0.8))
  "Face for modeline indicators (e.g. see my `notmuch-indicator')."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-red
  '((default :inherit bold)
    (((class color) (min-colors 88) (background light))
     :foreground "#880000")
    (((class color) (min-colors 88) (background dark))
     :foreground "#ff9f9f")
    (t :foreground "red"))
  "Face for modeline indicators (e.g. see my `notmuch-indicator')."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-red-bg
  '((default :inherit (bold minimal-modeline-indicator-button))
    (((class color) (min-colors 88) (background light))
     :background "#aa1111" :foreground "white")
    (((class color) (min-colors 88) (background dark))
     :background "#ff9090" :foreground "black")
    (t :background "red" :foreground "black"))
  "Face for modeline indicators with a background."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-green
  '((default :inherit bold)
    (((class color) (min-colors 88) (background light))
     :foreground "#005f00")
    (((class color) (min-colors 88) (background dark))
     :foreground "#73fa7f")
    (t :foreground "green"))
  "Face for modeline indicators (e.g. see my `notmuch-indicator')."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-green-bg
  '((default :inherit (bold minimal-modeline-indicator-button))
    (((class color) (min-colors 88) (background light))
     :background "#207b20" :foreground "white")
    (((class color) (min-colors 88) (background dark))
     :background "#77d077" :foreground "black")
    (t :background "green" :foreground "black"))
  "Face for modeline indicators with a background."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-yellow
  '((default :inherit bold)
    (((class color) (min-colors 88) (background light))
     :foreground "#6f4000")
    (((class color) (min-colors 88) (background dark))
     :foreground "#f0c526")
    (t :foreground "yellow"))
  "Face for modeline indicators (e.g. see my `notmuch-indicator')."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-yellow-bg
  '((default :inherit (bold minimal-modeline-indicator-button))
    (((class color) (min-colors 88) (background light))
     :background "#805000" :foreground "white")
    (((class color) (min-colors 88) (background dark))
     :background "#ffc800" :foreground "black")
    (t :background "yellow" :foreground "black"))
  "Face for modeline indicators with a background."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-blue
  '((default :inherit bold)
    (((class color) (min-colors 88) (background light))
     :foreground "#00228a")
    (((class color) (min-colors 88) (background dark))
     :foreground "#88bfff")
    (t :foreground "blue"))
  "Face for modeline indicators (e.g. see my `notmuch-indicator')."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-blue-bg
  '((default :inherit (bold minimal-modeline-indicator-button))
    (((class color) (min-colors 88) (background light))
     :background "#0000aa" :foreground "white")
    (((class color) (min-colors 88) (background dark))
     :background "#77aaff" :foreground "black")
    (t :background "blue" :foreground "black"))
  "Face for modeline indicators with a background."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-magenta
  '((default :inherit bold)
    (((class color) (min-colors 88) (background light))
     :foreground "#6a1aaf")
    (((class color) (min-colors 88) (background dark))
     :foreground "#e0a0ff")
    (t :foreground "magenta"))
  "Face for modeline indicators (e.g. see my `notmuch-indicator')."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-magenta-bg
  '((default :inherit (bold minimal-modeline-indicator-button))
    (((class color) (min-colors 88) (background light))
     :background "#6f0f9f" :foreground "white")
    (((class color) (min-colors 88) (background dark))
     :background "#e3a2ff" :foreground "black")
    (t :background "magenta" :foreground "black"))
  "Face for modeline indicators with a background."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-cyan
  '((default :inherit bold)
    (((class color) (min-colors 88) (background light))
     :foreground "#004060")
    (((class color) (min-colors 88) (background dark))
     :foreground "#30b7cc")
    (t :foreground "cyan"))
  "Face for modeline indicators (e.g. see my `notmuch-indicator')."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-cyan-bg
  '((default :inherit (bold minimal-modeline-indicator-button))
    (((class color) (min-colors 88) (background light))
     :background "#006080" :foreground "white")
    (((class color) (min-colors 88) (background dark))
     :background "#40c0e0" :foreground "black")
    (t :background "cyan" :foreground "black"))
  "Face for modeline indicators with a background."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-gray
  '((t :inherit shadow))
  "Face for modeline indicators (e.g. see my `notmuch-indicator')."
  :group 'minimal-modeline-faces)

(defface minimal-modeline-indicator-gray-bg
  '((default :inherit (bold minimal-modeline-indicator-button))
    (((class color) (min-colors 88) (background light))
     :background "#808080" :foreground "white")
    (((class color) (min-colors 88) (background dark))
     :background "#a0a0a0" :foreground "black")
    (t :inverse-video t))
  "Face for modeline indicatovrs with a background."
  :group 'minimal-modeline-faces)

;;;; Common helper functions

(defun minimal-modeline--string-truncate-p (str)
  "Return non-nil if STR should be truncated."
  (cond
   ((or (not (stringp str))
	(string-empty-p str)
	(string-blank-p str))
    nil)
   ((and (minimal-common-window-narrow-p)
	 (> (length str) minimal-modeline-string-truncate-length)
	 (not (one-window-p :no-minibuffer))))))

(defun minimal-modeline--truncate-p ()
  "Return non-nil if truncation should happen.
This is a more general and less stringent variant of
`minimal-modeline--string-truncate-p'."
  (and (minimal-common-window-narrow-p)
       (not (one-window-p :no-minibuffer))))

(defun minimal-modeline-string-cut-end (str)
  "Return truncated STR, if appropriate, else return STR.
Cut off the end of STR by counting from its start up to
`minimal-modeline-string-truncate-length'."
  (if (minimal-modeline--string-truncate-p str)
      (concat (substring str 0 minimal-modeline-string-truncate-length) "...")
    str))

(defun minimal-modeline-string-cut-beginning (str)
  "Return truncated STR, if appropriate, else return STR.
Cut off the beginning of STR by counting from its end up to
`minimal-modeline-string-truncate-length'."
  (if (minimal-modeline--string-truncate-p str)
      (concat "..." (substring str (- minimal-modeline-string-truncate-length)))
    str))

(defun minimal-modeline-string-cut-middle (str)
  "Return truncated STR, if appropriate, else return STR.
Cut off the middle of STR by counting half of
`minimal-modeline-string-truncate-length' both from its beginning
and end."
  (let ((half (floor minimal-modeline-string-truncate-length 2)))
    (if (minimal-modeline--string-truncate-p str)
	(concat (substring str 0 half) "..." (substring str (- half)))
      str)))

(defun minimal-modeline--first-char (str)
  "Return first character from STR."
  (substring str 0 1))

(defun minimal-modeline-string-abbreviate (str)
  "Abbreviate STR individual hyphen or underscore separated words.
Also see `minimal-modeline-string-abbreviate-but-last'."
  (if (minimal-modeline--string-truncate-p str)
      (mapconcat #'minimal-modeline--first-char (split-string str "[_-]") "-")
    str))

(defun minimal-modeline-string-abbreviate-but-last (str nthlast)
  "Abbreviate STR, keeping NTHLAST words intact.
Also see `minimal-modeline-string-abbreviate'."
  (if (minimal-modeline--string-truncate-p str)
      (let* ((all-strings (split-string str "[_-]"))
	     (nbutlast-strings (nbutlast (copy-sequence all-strings) nthlast))
	     (last-strings (nreverse (ntake nthlast (nreverse (copy-sequence all-strings)))))
	     (first-component (mapconcat #'minimal-modeline--first-char nbutlast-strings "-"))
	     (last-component (mapconcat #'identity last-strings "-")))
	(if (string-empty-p first-component)
	    last-component
	  (concat first-component "-" last-component)))
    str))

;;;; Keyboard macro indicator

(defvar-local minimal-modeline-kbd-macro
    '(:eval
      (when (and (mode-line-window-selected-p) defining-kbd-macro)
	(propertize " KMacro " 'face 'minimal-modeline-indicator-blue-bg)))
  "Mode line construct displaying `mode-line-defining-kbd-macro'.
Specific to the current window's mode line.")

;;;; Narrow indicator

(defvar-local minimal-modeline-narrow
    '(:eval
      (when (and (mode-line-window-selected-p)
		 (buffer-narrowed-p)
		 (not (derived-mode-p 'Info-mode 'help-mode 'special-mode 'message-mode)))
	(propertize " Narrow " 'face 'minimal-modeline-indicator-cyan-bg)))
  "Mode line construct to report the narrowed state of the current buffer.")

;;;; Input method

(defvar-local minimal-modeline-input-method
    '(:eval
      (when current-input-method-title
	(propertize (format " %s " current-input-method-title)
		    'face 'minimal-modeline-indicator-green-bg
		    'mouse-face 'mode-line-highlight)))
  "Mode line construct to report the multilingual environment.")

;;;; Buffer status

;; TODO 2023-07-05: What else is there beside remote files?  If
;; nothing, this must be renamed accordingly.
(defvar-local minimal-modeline-buffer-status
    '(:eval
      (when (file-remote-p default-directory)
	(propertize " @ "
		    'face 'minimal-modeline-indicator-red-bg
		    'mouse-face 'mode-line-highlight)))
  "Mode line construct for showing remote file name.")

;;;; Dedicated window

(defvar-local minimal-modeline-window-dedicated-status
    '(:eval
      (when (window-dedicated-p)
	(propertize " = "
		    'face 'minimal-modeline-indicator-gray-bg
		    'mouse-face 'mode-line-highlight)))
  "Mode line construct for dedicated window indicator.")

;;;; Buffer name and modified status

(defun minimal-modeline-buffer-identification-face ()
  "Return appropriate face or face list for `minimal-modeline-buffer-identification'."
  (let ((file (buffer-file-name)))
    (cond
     ((and (mode-line-window-selected-p)
	   file
	   (buffer-modified-p))
      '(italic mode-line-buffer-id))
     ((and file (buffer-modified-p))
      'italic)
     ((mode-line-window-selected-p)
      'mode-line-buffer-id))))

(defun minimal-modeline--buffer-name ()
  "Return `buffer-name', truncating it if necessary.
See `minimal-modeline-string-cut-middle'."
  (when-let* ((name (buffer-name)))
    (minimal-modeline-string-cut-middle name)))

(defun minimal-modeline-buffer-name ()
  "Return buffer name, with read-only indicator if relevant."
  (let ((name (minimal-modeline--buffer-name)))
    (if buffer-read-only
	(format "%s %s" (char-to-string #xE0A2) name)
      name)))

(defun minimal-modeline-buffer-name-help-echo ()
  "Return `help-echo' value for `minimal-modeline-buffer-identification'."
  (concat
   (propertize (buffer-name) 'face 'mode-line-buffer-id)
   "\n"
   (propertize
    (or (buffer-file-name)
	(format "No underlying file.\nDirectory is: %s" default-directory))
    'face 'font-lock-doc-face)))

(defvar-local minimal-modeline-buffer-identification
    '(:eval
      (propertize (minimal-modeline-buffer-name)
		  'face (minimal-modeline-buffer-identification-face)
		  'mouse-face 'mode-line-highlight
		  'help-echo (minimal-modeline-buffer-name-help-echo)))
  "Mode line construct for identifying the buffer being displayed.
Propertize the current buffer with the `mode-line-buffer-id'
face.  Let other buffers have no face.")

;;;; Major mode

(defun minimal-modeline-major-mode-icon (&optional face)
  "Return icon for the major mode, optionally propertized with FACE."
  (minimal-icons-get-icon major-mode face))

(defun minimal-modeline-major-mode-name ()
  "Return capitalized `major-mode' without the -mode suffix."
  (capitalize (string-replace "-mode" "" (symbol-name major-mode))))

(defun minimal-modeline-major-mode-help-echo ()
  "Return `help-echo' value for `minimal-modeline-major-mode'."
  (if-let* ((parent (get major-mode 'derived-mode-parent)))
      (format "Symbol: `%s'.  Derived from: `%s'" major-mode parent)
    (format "Symbol: `%s'." major-mode)))

(defvar-local minimal-modeline-major-mode
    (list
     (propertize "%[" 'face 'minimal-modeline-indicator-red)
     '(:eval
       (concat
	(minimal-modeline-major-mode-icon (unless (mode-line-window-selected-p) 'shadow))
	" "
	(propertize
	 (minimal-modeline-string-abbreviate-but-last
	  (minimal-modeline-major-mode-name)
	  2)
	 'mouse-face 'mode-line-highlight
	 'help-echo (minimal-modeline-major-mode-help-echo))))
     (propertize "%]" 'face 'minimal-modeline-indicator-red))
  "Mode line construct for displaying major modes.")

(defvar-local minimal-modeline-process
    (list '("" mode-line-process))
  "Mode line construct for the running process indicator.")

;;;; Git branch and diffstat

(declare-function vc-git--symbolic-ref "vc-git" (file))

(defun minimal-modeline--vc-branch-name (file backend)
  "Return capitalized VC branch name for FILE with BACKEND."
  (when-let* ((rev (vc-working-revision file backend))
	      (branch (or (vc-git--symbolic-ref file)
			  (substring rev 0 7))))
    (capitalize branch)))

(declare-function vc-git-working-revision "vc-git" (file))

(defvar minimal-modeline-vc-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line down-mouse-1] 'vc-diff)
    (define-key map [mode-line down-mouse-3] 'vc-root-diff)
    map)
  "Keymap to display on VC indicator.")

(defun minimal-modeline--vc-help-echo (file)
  "Return `help-echo' message for FILE tracked by VC."
  (format "Revision: %s\nmouse-1: `vc-diff'\nmouse-3: `vc-root-diff'"
	  (vc-working-revision file)))

(defun minimal-modeline--vc-text (file branch &optional face)
  "Prepare text for Git controlled FILE, given BRANCH.
With optional FACE, use it to propertize the BRANCH."
  (concat
   (propertize (char-to-string #xE0A0) 'face 'shadow)
   " "
   (propertize branch
	       'face face
	       'mouse-face 'mode-line-highlight
	       'help-echo (minimal-modeline--vc-help-echo file)
	       'local-map minimal-modeline-vc-map)))

(defun minimal-modeline--vc-details (file branch &optional face)
  "Return Git BRANCH details for FILE, truncating it if necessary.
The string is truncated if the width of the window is smaller
than `split-width-threshold'."
  (minimal-modeline-string-cut-end
   (minimal-modeline--vc-text file branch face)))

(defvar minimal-modeline--vc-faces
  '((added . vc-locally-added-state)
    (edited . vc-edited-state)
    (removed . vc-removed-state)
    (missing . vc-missing-state)
    (conflict . vc-conflict-state)
    (locked . vc-locked-state)
    (up-to-date . vc-up-to-date-state))
  "VC state faces.")

(defun minimal-modeline--vc-get-face (key)
  "Get face from KEY in `minimal-modeline--vc-faces'."
  (alist-get key minimal-modeline--vc-faces 'vc-up-to-date-state))

(defun minimal-modeline--vc-face (file backend)
  "Return VC state face for FILE with BACKEND."
  (when-let* ((key (vc-state file backend)))
    (minimal-modeline--vc-get-face key)))

(defvar-local minimal-modeline-vc-branch
    '(:eval
      (when-let* (((mode-line-window-selected-p))
		  (file (or buffer-file-name default-directory))
		  (backend (or (vc-backend file) 'Git))
		  ;; ((vc-git-registered file))
		  (branch (minimal-modeline--vc-branch-name file backend))
		  (face (minimal-modeline--vc-face file backend)))
	(minimal-modeline--vc-details file branch face)))
  "Mode line construct to return propertized VC branch.")

;;;; Flymake errors, warnings, notes

(declare-function flymake--severity "flymake" (type))
(declare-function flymake-diagnostic-type "flymake" (diag))

;; Based on `flymake--mode-line-counter'.
(defun minimal-modeline-flymake-counter (type)
  "Compute number of diagnostics in buffer with TYPE's severity.
TYPE is usually keyword `:error', `:warning' or `:note'."
  (let ((count 0))
    (dolist (d (flymake-diagnostics))
      (when (= (flymake--severity type)
	       (flymake--severity (flymake-diagnostic-type d)))
	(cl-incf count)))
    (when (cl-plusp count)
      (number-to-string count))))

(defvar minimal-modeline-flymake-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line down-mouse-1] 'flymake-show-buffer-diagnostics)
    (define-key map [mode-line down-mouse-3] 'flymake-show-project-diagnostics)
    map)
  "Keymap to display on Flymake indicator.")

(defmacro minimal-modeline-flymake-type (type indicator &optional face)
  "Return function that handles Flymake TYPE with stylistic INDICATOR and FACE."
  `(defun ,(intern (format "minimal-modeline-flymake-%s" type)) ()
     (when-let* ((count (minimal-modeline-flymake-counter
			 ,(intern (format ":%s" type)))))
       (concat
	(propertize ,indicator 'face 'shadow)
	(propertize count
		    'face ',(or face type)
		    'mouse-face 'mode-line-highlight
		    ;; FIXME 2023-07-03: Clicking on the text with
		    ;; this buffer and a single warning present, the
		    ;; diagnostics take up the entire frame.  Why?
		    'local-map minimal-modeline-flymake-map
		    'help-echo "mouse-1: buffer diagnostics\nmouse-3: project diagnostics")))))

(minimal-modeline-flymake-type error "☣")
(minimal-modeline-flymake-type warning "!")
(minimal-modeline-flymake-type note "·" success)

(defvar-local minimal-modeline-flymake
    `(:eval
      (when (and (bound-and-true-p flymake-mode)
		 (mode-line-window-selected-p))
	(list
	 ;; See the calls to the macro `minimal-modeline-flymake-type'
	 '(:eval (minimal-modeline-flymake-error))
	 '(:eval (minimal-modeline-flymake-warning))
	 '(:eval (minimal-modeline-flymake-note)))))
  "Mode line construct displaying `flymake-mode-line-format'.
Specific to the current window's mode line.")

;;;; Eglot

(with-eval-after-load 'eglot
  (setq mode-line-misc-info
	(delete '(eglot--managed-mode (" [" eglot--mode-line-format "] ")) mode-line-misc-info)))

(defvar-local minimal-modeline-eglot
    `(:eval
      (when (and (featurep 'eglot) (mode-line-window-selected-p))
	'(eglot--managed-mode eglot--mode-line-format)))
  "Mode line construct displaying Eglot information.
Specific to the current window's mode line.")

;;;; Frame name

(defcustom minimal-modeline-show-frame-name nil
  "When non-nil, display the current frame name."
  :type 'boolean)

(defvar-local minimal-modeline-frame-name
  '(minimal-modeline-show-frame-name
    (" "
     (:eval (when-let* ((_ (mode-line-window-selected-p))
			(current-frame (selected-frame))
			(_ (frame-live-p current-frame))
			(parameters (frame-parameters))
			(name (capitalize (alist-get 'name parameters)))
			(indicator "√"))
	      (format "%s %s " (propertize indicator 'face 'shadow) name)))))
  "Mode line construct to display the current frame name.")

;;;; `which-function-mode' indicator

(defvar-local minimal-modeline-which-function-indicator
  `(( :propertize
      which-func-current
      face (minimal-modeline-indicator-small which-func)
      mouse-face mode-line-highlight
      help-echo (format "Current definition: `%s'"
			(or (gethash (selected-window) which-func-table)
			    which-func-unknown))))
  "The equivalent of `which-func-format'.")

(with-eval-after-load 'which-func
  (setq mode-line-misc-info (delete (assq 'which-function-mode mode-line-misc-info) mode-line-misc-info)))

;;;; Miscellaneous

(defvar-local minimal-modeline-notmuch-indicator
    '(notmuch-indicator-mode
      (" "
       (:eval (when (mode-line-window-selected-p)
		notmuch-indicator--counters))))
  "The equivalent of `notmuch-indicator-mode-line-construct'.
Display the indicator only on the focused window's mode line.")

(defvar-local minimal-modeline-misc-info
    '(:eval
      (when (mode-line-window-selected-p)
	mode-line-misc-info))
  "Mode line construct displaying `mode-line-misc-info'.
Specific to the current window's mode line.")

;;;; Risky local variables

;; NOTE 2023-04-28: The `risky-local-variable' is critical, as those
;; variables will not work without it.
(dolist (construct '(minimal-modeline-kbd-macro
		     minimal-modeline-narrow
		     minimal-modeline-input-method
		     minimal-modeline-buffer-status
		     minimal-modeline-window-dedicated-status
		     minimal-modeline-buffer-identification
		     minimal-modeline-major-mode
		     minimal-modeline-process
		     minimal-modeline-vc-branch
		     minimal-modeline-flymake
		     minimal-modeline-eglot
		     minimal-modeline-frame-name
		     minimal-modeline-which-function-indicator
		     minimal-modeline-notmuch-indicator
		     minimal-modeline-misc-info))
  (put construct 'risky-local-variable t))

(provide 'minimal-lisp-modeline)
