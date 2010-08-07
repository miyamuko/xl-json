;;;; -*- mode: lisp; package: json -*-
;;;;
;;;; File: json/utils.l
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

(defparameter *json-lisp-escaped-chars*
  `(("\\\"" . "\"")
    ("\\\\" . "\\")
    ("\\/" . "/")
    ("\\b" . "\b")
    ("\\f" . "\f")
    ("\\n" . "\n")
    ("\\r" . "\r")
    ("\\t" . "\t")))

(defmacro json-char->lisp-char (json-char)
  `(cdr (assoc ,json-char *json-lisp-escaped-chars*
               :test #'string=)))

(defmacro lisp-char->json-char (lisp-char)
  `(car (rassoc ,lisp-char *json-lisp-escaped-chars*
                :test #'string=)))

(defmacro encode-unicode-char (code)
  `(format nil "\\u~4,'0x" ,code))

(defun json-array-p (value)
  (or (simple-vector-p value)
      (listp value)))

(defun json-object-p (value)
  (or (hash-table-p value)
      (alistp value)))

(defun alistp (list)
  (and (listp list)
       (every #'(lambda (e)
                  (and (consp e)
                       (atom (car e))))
              list)))

(defun ensure-json-object (json)
  (unless (json-object-p json)
    (error 'type-error
           :datum json
           :expected-type "JSON object (hash-table or alist)")))

(defun mapseq (function sequence &rest more-sequences)
  (apply 'map `(nil ,function ,sequence ,@more-sequences)))


(defun re-union (&rest re-list)
  (format nil "~{\\(~A\\)~^\\|~}" re-list))




(defun D0(&rest args)
  (msgbox "~S~%line=~D, col=~D, point=~D~%[~A~A]"
          args
          (current-line-number) (current-column) (point)
          (char-before (point))
          (char-after (point))
          )
  (car (last args)))


(provide "json/utils")

;;;; End
