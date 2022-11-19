;;; flymake-posframe.el --- Display flymake diagnostics at point

;;; Commentary:

;; Stolen, in large parts, from https://github.com/Ladicle/flymake-posframe

;;; Code:

(require 'flymake)
(require 'posframe)

(defcustom flymake-posframe-prefix "\u27a4 "
  "String to be displayed before every default message in posframe."
  :group 'flymake-posframe
  :type 'string)

(defface flymake-posframe-background-face
  '((t :inherit tooltip))
  "The background color of the flymake-posframe frame.
Only the `background' is used in this face."
  :group 'flymake-posframe)

(defface flymake-posframe-foreground-face
  '((t :inherit tooltip))
  "The background color of the flymake-posframe frame.
Only the `foreground' is used in this face."
  :group 'flymake-posframe)

(defcustom flymake-posframe-buffer " *flymake-posframe-buffer*"
  "Name of the flymake posframe buffer."
  :group 'flymake-posframe
  :type 'string)

(defvar flymake-posframe-hide-posframe-hooks
  '(pre-command-hook post-command-hook focus-out-hook)
  "The hooks which should trigger automatic removal of the posframe.")

(defun flymake-posframe-hide ()
  "Hide the posframe buffer."
  (posframe-hide flymake-posframe-buffer)
  (dolist (hook flymake-posframe-hide-posframe-hooks)
    (remove-hook hook #'flymake-posframe-hide t)))

(defun flymake-posframe-format (diag)
  "Format the diagnostic (DIAG) info for display."
  (let ((category (get (flymake-diagnostic-type diag) 'flymake-category))
        (text (flymake-diagnostic-text diag)))
    (concat
     flymake-posframe-prefix
     (pcase category
       ('flymake-error
        (propertize text 'face 'compilation-error))
       ('flymake-warning
        (propertize text 'face 'compilation-warning))
       ('flymake-note
        (propertize text 'face 'compilation-info))))))

(defvar-local flymake-posframe-current-diag nil
  "Currently displayed diagnotic at point.")

(defun flymake-posframe-display ()
  "Refresh the display at point."
  (when flymake-mode
    (if-let ((diag (get-char-property (point) 'flymake-diagnostic)))
        (unless (and (eq diag flymake-posframe-current-diag)
                     (frame-visible-p (buffer-local-value 'posframe--frame (get-buffer flymake-posframe-buffer))))
          (setq flymake-posframe-current-diag diag)
          (let ((msg (flymake-posframe-format diag)))
;;          (let ((category (get (flymake-diagnostic-type diag) 'flymake-category)))
;;            (let ((prop (propertize
;;		         (pcase category
;;                           ('flymake-error flymake-posframe-prefix)
;;                           ('flymake-warning flymake-posframe-prefix)
;;                           ('flymake-note flymake-posframe-prefix))
;;                         'face 'warning)))
;;              (let ((msg (concat prop
;;			         (flymake--diag-text diag))))
            (posframe-show
             flymake-posframe-buffer
	     :internal-border-width 3
	     :left-fringe 1
	     :right-fringe 1
	     :foreground-color (face-foreground 'flymake-posframe-foreground-face nil t)
	     :background-color (face-background 'flymake-posframe-background-face nil t)
             :string msg)
            
	    (let ((current-posframe-frame
		   (buffer-local-value 'posframe--frame (get-buffer flymake-posframe-buffer))))
	      (redirect-frame-focus current-posframe-frame (frame-parent current-posframe-frame)))
            
	    (dolist (hook flymake-posframe-hide-posframe-hooks)
	      (add-hook hook #'flymake-posframe-hide nil t))))
      (flymake-posframe-hide))))

(define-minor-mode flymake-posframe-mode
  "Minor mode for displaying flymake diagnostics at point."
  :group flymake-posframe
  (cond
   (flymake-posframe-mode
    (add-hook 'post-command-hook #'flymake-posframe-display nil 'local))
   (t
    (remove-hook 'post-command-hook #'flymake-posframe-display 'local))))

(provide 'flymake-posframe)
;;; flymake-posframe.el ends here
