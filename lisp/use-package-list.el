;;; use-package-list.el --- List use-package declarations in config file

;; Copyright (C) 2017 Matthew Bauer
;; Author: Matthew Bauer <mjbauer95@gmail.com>

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; ‘ensure’ packages at compile time.

;;; Code:

(require 'json)
(require 'use-package)
(eval-when-compile
  (require 'cl))

(defun use-package-list (script)
  "Count use-package declarations listed in SCRIPT."

  (setq use-package-list--is-running t)
  (lexical-let ((use-package-verbose t)
                (use-package-debug t)
                (use-package-always-ensure nil)
                (use-package-always-defer t)
                (use-package-list--packages nil)
                (use-package-list--is-running t)
                (use-package-ensure-function 'ignore)
                )
    (advice-add 'use-package
                :before (lambda (name &rest args)
                          (unless (or (member :disabled args)
                                      (and (member :ensure args)
                                           (not (plist-get args :ensure))))
                            (when (and (member :ensure args)
                                       (symbolp (plist-get args :ensure)))
                              (setq name (plist-get args :ensure)))
                            (add-to-list 'use-package-list--packages name))))

    (defmacro define-hook-helper (&rest args))
    (defmacro create-hook-helper (&rest args))

    (advice-add 'use-package-handler/:defer
                :around (lambda (x name keyword arg rest state)
                          (let ((body (use-package-process-keywords name rest
                                        (plist-put state :deferred t)))
                                (name-string (use-package-as-string name)))
                            (dolist (command
                                     (delete-dups (plist-get state :commands)))
                              (unless (or
                                       (string= (symbol-name command)
                                                "create-hook-helper")
                                       (string= (symbol-name command)
                                                "define-hook-helper"))
                                (fset command (lambda (&rest args)))))
                            body)))

    (advice-add 'use-package-load-name :override #'ignore)

    (load script nil nil t)

    (princ (json-encode use-package-list--packages))

    use-package-list--packages))

(provide 'use-package-list)
;;; use-package-list.el ends here
