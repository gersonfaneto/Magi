;;; minimal-writing.el --- Prose, typography, Org, and tabs -*- lexical-binding: t; -*-

;;; Commentary:
;; Spacious padding, mixed pitch, Olivetti, Org, and project tab groups.

;;; Code:

(require 'project)

;; --- Writing and Presentation ---
;; Give frames and windows more breathing room.
(use-package spacious-padding
  :hook (after-init . spacious-padding-mode)
  :custom
  (spacious-padding-widths
   '(:internal-border-width 16
     :header-line-width 4
     :mode-line-width 6
     :tab-width 4
     :right-divider-width 24
     :scroll-bar-width 0
     :fringe-width 8))
  (spacious-padding-subtle-frame-lines t))

;; Mix fixed-pitch code with variable-pitch prose in writing buffers.
(use-package mixed-pitch
  :straight (:type git :host gitlab :repo "jabranham/mixed-pitch" :protocol https)
  :hook
  ((org-mode . mixed-pitch-mode)
   (markdown-mode . mixed-pitch-mode))
  :custom
  (mixed-pitch-variable-pitch-cursor nil)
  (mixed-pitch-set-height nil))

;; Center prose buffers at a comfortable line width.
(use-package olivetti
  :hook
  ((org-mode . olivetti-mode)
   (markdown-mode . olivetti-mode))
  :bind
  ("C-c o t" . olivetti-mode)
  :custom
  (olivetti-body-width 100)
  (olivetti-style 'fancy))

;; --- Org Mode ---
(use-package org
  :straight nil
  :ensure nil
  :hook
  (org-mode . visual-line-mode)
  :bind
  ("C-c o a" . org-agenda)
  ("C-c o c" . org-capture)
  ("C-c o l" . org-store-link)
  :custom
  (org-directory minimal/org-directory)
  (org-default-notes-file (expand-file-name "inbox.org" minimal/org-directory))
  (org-agenda-files (list minimal/org-directory))
  (org-startup-indented t)
  (org-startup-folded 'content)
  (org-hide-emphasis-markers t)
  (org-ellipsis " ...")
  (org-return-follows-link t)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-src-preserve-indentation t)
  (org-edit-src-content-indentation 0)
  (org-log-done 'time)
  (org-use-speed-commands t)
  :config
  (setq org-capture-templates
        `(("t" "Task" entry
           (file+headline ,(expand-file-name "inbox.org" minimal/org-directory) "Tasks")
           "* TODO %?\n%U\n" :empty-lines 1)
          ("n" "Note" entry
           (file+headline ,(expand-file-name "inbox.org" minimal/org-directory) "Notes")
           "* %?\n%U\n" :empty-lines 1))))

;; --- Tab Bar ---
(defun minimal/tab-bar-group-by-project (tab)
  "Return TAB's project name, or nil when it does not belong to one."
  (let ((buffer (if (eq (car tab) 'current-tab)
                    (window-buffer (frame-selected-window))
                  (car (alist-get 'wc-bl tab)))))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (when-let* ((project (project-current)))
          (project-name project))))))

(use-package tab-bar
  :straight nil
  :ensure nil
  :hook (after-init . tab-bar-mode)
  :init
  (setq tab-bar-show 1
        tab-bar-close-button-show nil
        tab-bar-tab-name-function #'tab-bar-tab-name-current-with-count
        tab-bar-tab-group-function #'minimal/tab-bar-group-by-project
        tab-bar-format '(tab-bar-format-history
                         tab-bar-format-tabs-groups
                         tab-bar-separator
                         tab-bar-format-add-tab))
  :config
  (tab-bar-history-mode 1))

(provide 'minimal-writing)

;;; minimal-writing.el ends here
