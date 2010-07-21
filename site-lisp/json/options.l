;;;; -*- mode: lisp; package: json -*-
;;;;
;;;; File: json/options.l
;;;;
;;;; License:
;;;;
;;;;   Copyright (c) 2008 MIYAMUKO Katsuyuki.
;;;;
;;;;   json is released under an MIT license.
;;;;   See json/docs/MIT-LICENSE for full license.
;;;;

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "json/package")
  )

(in-package :json)

(defparameter *option-definitions* nil)

(defmacro define-keyword-option (name &optional default valid-values function)
  (let ((take (intern (format nil "option-~A" name)))
        (check (intern (format nil "option-~A-validate!" name))))
  `(progn
     (defun ,check (v)
       ,(if valid-values
            `(progn
               (unless ,(if function
                            `(member (if (functionp v) v (and (fboundp v) (symbol-function v)))
                                     ,valid-values
                                     :key 'symbol-function)
                          `(member v ,valid-values))
                 (raise-json-argument-error "invalid `~S' option: `~S', valid ~A are ~{~S~^, ~}."
                                            ,name v ,(if function "functions" "values") ,valid-values))
               v)
          t))
     (defmacro ,take (options)
       `(let ((pair (assoc ,,name options)))
          (if pair
              (cdr pair)
            ,',default)))
     (push (cons ,name ',check) *option-definitions*)
     )))

(define-keyword-option :strict t)
(define-keyword-option :padding nil)

(define-keyword-option :json-null nil)
(define-keyword-option :json-true t)
(define-keyword-option :json-false nil)

(define-keyword-option :json-array :list '(:array :list))
(define-keyword-option :json-object :alist '(:hash-table :alist))
(define-keyword-option :hash-table-test 'equal '(eq eql equal equalp) t)


(defun parse-options (keywords)
  (let ((options (parse-keyword-list keywords)))
    (validate-options options)
    options))

(defun validate-options (options)
  (dolist (pair options)
    (let ((fn (cdr (assoc (car pair) *option-definitions*))))
      (when fn
        (funcall fn (cdr pair))))))

(defun parse-keyword-list (keywords)
  (labels ((list->alist (lst)
             (if lst
                 (cons (cons (car lst) (cadr lst))
                       (list->alist (cddr lst)))
               nil)))
    (cond ((null keywords)
           nil)
          ((oddp (length keywords))
           (error (make-condition 'too-few-arguments :datum keywords)))
          (t
           (list->alist keywords)))))



(provide "json/options")

;;;; End
