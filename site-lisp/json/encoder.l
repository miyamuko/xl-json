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
          json-encode-to-buffer
          json-encode-to-stream
          ))


(defun json-encode (json-object &rest options)
  (with-output-to-string (out)
    (apply 'json-encode-to-stream out json-object options)))

(defun json-encode-to-buffer (buffer-or-name json-object &rest options)
  (check-type buffer-or-name (or buffer string))
  (let ((buffer (if (bufferp buffer-or-name)
                    buffer-or-name
                  (get-buffer-create buffer-or-name))))
    (with-open-stream (out (make-buffer-stream buffer))
      (apply 'json-encode-to-stream out json-object options))))

(defun json-encode-to-stream (stream json-object &rest options)
  (let ((options (parse-options options)))
    (let ((*standard-output* stream))
      (json-write-toplevel json-object options)
      )))


(defun json-write-toplevel (object options)
  (when (and (option-strict options)
             (not (or (json-object-p object)
                      (json-array-p object))))
    (raise-json-argument-error "~S (~A) not allowed (only arrays or objects). Try :strict nil option."
                               object (type-of object)))
  (if (option-padding options)
      (json-write-toplevel-with-padding object options)
    (json-write-toplevel object options)))

(defun json-write-toplevel-with-padding (object options)
  (puts (option-padding options))
  (puts "(")
  (json-write-toplevel object options)
  (puts ")"))

(defun json-write-toplevel (object options)
  (cond ((simple-vector-p object)
         (json-write-array object options))
        ((hash-table-p object)
         (json-write-hash-table object options))
        ((null object)
         (if (eq (option-json-object options) :hash-table)
             (json-write-list object options)
           (json-write-alist object options)))
        ((alistp object)
         (json-write-alist object options))
        ((listp object)
         (json-write-list object options))
        (t
         (raise-json-argument-error "~S (~A) not supported in toplevel" object (type-of object)))))

(defun json-write-value (object options)
  (cond ((eql (option-json-null options) object)
         (json-write-bare-word "null" options))
        ((eql (option-json-true options) object)
         (json-write-bare-word "true" options))
        ((eql (option-json-false options) object)
         (json-write-bare-word "false" options))
        ((null object)
         (json-write-list object options))
        ((stringp object)
         (json-write-string object options))
        ((characterp object)
         (json-write-character object options))
        ((symbolp object)
         (json-write-string (symbol-name object) options))
        ((numberp object)
         (json-write-number object options))
        ((simple-vector-p object)
         (json-write-array object options))
        ((hash-table-p object)
         (json-write-hash-table object options))
        ((alistp object)
         (json-write-alist object options))
        ((listp object)
         (json-write-list object options))
        (t
         (raise-json-argument-error "~S (~A) not supported" object (type-of object)))))


(defun json-write-bare-word (object options)
  (puts object))

(defparameter *json-char-kind*
  (compile-regexp
   (re-union "[/\b\t\n\r\t\f\"\\]"             ; special char
             "[\Xd600-\Xd6ff][\Xd700-\Xd7ff]"  ; undef unicode char
             )))
(defun json-write-string (object options)
  (puts "\"")
  (let ((last-match 0))
    (while (string-match *json-char-kind* object last-match)
      (map nil #'(lambda (char)
                   (let ((code (char-unicode char)))
                     (if (< code #x7f)
                         (puts (string char))
                       (puts (encode-unicode-char code)))))
           (substring object last-match (match-beginning 0)))
      (cond ((match-string 1) ; special char
             (puts (lisp-char->json-char (match-string 1))))
            ((match-string 2) ; undef unicode char
             (let ((undef (match-string 2)))
               (puts (encode-unicode-char
                      (combine-undef-char (undef-char-high (char-code (char undef 0)))
                                          (undef-char-low (char-code (char undef 1)))))))))
      (setf last-match (match-end 0)))
    (map nil #'(lambda (char)
                 (let ((code (char-unicode char)))
                   (if (< code #x7f)
                       (puts (string char))
                     (puts (encode-unicode-char code)))))
         (substring object last-match)))
  (puts "\"")
  )

(defun json-write-character (object options)
  (json-write-string (string object) options))

(defun json-write-number (object options)
  (cond ((integerp object)
         (puts "~D" object))
        ((single-float-p object)
         (puts "~F" object))
        ((double-float-p object)
         (puts (substitute #\e #\d (format nil "~F" object))))
        (t
         (raise-json-argument-error "~S (~A) not supported" object (type-of object)))))

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
