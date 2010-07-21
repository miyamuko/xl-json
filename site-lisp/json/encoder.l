;;;; -*- mode: lisp; package: json -*-
;;;;
;;;; File: json/encoder.l
;;;;
;;;; License:
;;;;
;;;;   Copyright (c) 2008,2010 MIYAMUKO Katsuyuki.
;;;;
;;;;   json is released under an MIT license.
;;;;   See json/docs/MIT-LICENSE for full license.
;;;;

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "json/base")
  (require "json/options")
  (require "json/unicode")
  )

(in-package :json)

(export '(json-encode
          ))


(defun json-encode (json-object &rest options)
  (let ((options (parse-options options)))
    (with-output-to-string (out)
      (let ((*standard-output* out))
        (json-write-value json-object options)
        ))))

(defun json-write-value (object options)
  (cond ((stringp object)
         (json-write-string object options))
        ((symbolp object)
         (json-write-string (symbol-name object) options))
        ((numberp object)
         (json-write-number object options))
        ((arrayp object)
         (json-write-array object options))
        ((hash-table-p object)
         (json-write-hash-table object options))
        ((maybe-alistp object)
         (json-write-alist object options))
        ((listp object)
         (json-write-list object options))
        (t
         (plain-error "TODO"))))


(defparameter *json-char-kind*
  (compile-regexp
   (re-union "[/\b\t\n\r\t\"\\]"               ; special char
             "[\x20-\x7F]+"                    ; ascii char
             "[\Xd600-\Xd6ff][\Xd700-\Xd7ff]"  ; undef unicode char
             "."                               ; other char
             )))
(defun json-write-string (object options)
  (puts "\"")
  (let ((start 0))
    (while (string-match *json-char-kind* object start)
      (setf start (match-end 0))
      (multiple-value-bind (special ascii undef other)
          (values-list (mapcar 'match-string '(1 2 3 4)))
        (cond (special
               (puts (lisp-char->json-char special)))
              (ascii
               (puts ascii))
              (undef
               (puts
                (encode-unicode-char
                 (combine-undef-char (undef-char-high (char-code (char undef 0)))
                                     (undef-char-low (char-code (char undef 1)))))))
              (other
               (let ((c (char-unicode (char other 0))))
                 (if (< c #x7f)
                     (puts other)
                   (puts (encode-unicode-char c)))))
              ))))
  (puts "\"")
  )

(defun json-write-number (object options)
  (puts (if (integerp object) "~D" "~F") object))

(defun json-write-list (object options)
  (write-each mapcar #'(lambda (obj)
                         (json-write-value obj options))
              object
              #\[ #\] #\,))

(defun json-write-array (object options)
  (write-each mapseq #'(lambda (obj)
                         (json-write-value obj options))
              object
              #\[ #\] #\,))

(defun json-write-hash-table (object options)
  (write-each maphash #'(lambda (k v)
                          (json-write-string (string k) options)
                          (puts ":")
                          (json-write-value v options))
              object
              #\{ #\} #\,))

(defun json-write-alist (object options)
  (write-each mapcar #'(lambda (e)
                         (json-write-string (string (car e)) options)
                         (puts ":")
                         (json-write-value (cdr e) options))
              object
              #\{ #\} #\,))


(provide "json/encoder")

;;; End
