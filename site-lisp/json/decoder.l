;;;; -*- mode: lisp; package: json -*-
;;;;
;;;; File: json/decoder.l
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
  )

(in-package :json)

(export '(json-decode
          json-decode-file
          ))

(defparameter *json-decode-buffer-name* " *json:decode*")

(defmacro skip-ws ()
  `(skip-chars-forward " \t\r\f\n"))

(defmacro skip-bare-word ()
  `(prog1
       (skip-chars-forward "^:,{}[]'\"")
     (skip-chars-backward " \t\r\f\n")))

(defmacro delete-json-padding ()
  `(progn
     (when (eq (char-before (point-max)) #\))
       (delete-region (1- (point-max)) (point-max)))
     (goto-char (point-min))
     (when (looking-at " *[^(){}:,\"']*(")
       (delete-region 0 (match-end 0)))))

(defmacro current-char ()
  `(char-after (point)))

(defmacro current-char= (char)
  `(progn
     (raise-if-eobp ,char)
     (eq (current-char) ,char)))

(defmacro raise-if-eobp (expect)
  `(when (eobp)
     (raise-end-of-json-error ,expect)))

(defmacro skip-char (char &optional expect)
  `(progn
     (unless (current-char= ,char)
       (raise-if-eobp (or ,expect ,char))
       (raise-json-parse-error "unexpected '~A', expecting '~A'"
                               (current-char) (or ,expect ,char)))
     (forward-char)))

(defmacro skip-char-if (char)
  `(when (current-char= ,char)
     (forward-char)))

(defmacro break-loop-if-char= (char)
  `(progn
     (when (skip-char-if ,char)
       (return))
     (raise-if-eobp ,char)
     ))

(defmacro current-bare-word ()
  `(let ((start (point))
         (end (and
               (skip-bare-word)
               (point))))
     (when (and start end)
       (buffer-substring start end))))

(defun scan-json-bare-value (options)
  (let ((word (current-bare-word)))
    (unless word
      (raise-if-eobp "json value")
      (raise-json-parse-error "unexpected '~A', expecting json value."
                              (current-char)))
    (cond ((equal "null" word)
           (option-json-null options))
          ((equal "true" word)
           (option-json-true options))
          ((equal "false" word)
           (option-json-false options))
          ((string-matchp "^-?\\(0\\|[1-9][0-9]*\\)\\(\\.[0-9]+\\)?\\([eE][+-]?[0-9]+\\)?$" word)
           (parse-json-number word))
          (t
           (when (option-strict options)
             (raise-json-parse-error "bare word not allowed."))
           word))))


(defparameter *unicode-char* "\\\\u[a-fA-F0-9]\\{4\\}")
(defparameter *escaped-char* "\\\\.")
(defparameter *re-double-quote-string*
  (compile-regexp (re-union *unicode-char* *escaped-char* "\"")))
(defparameter *re-single-quote-string*
  (compile-regexp (re-union *unicode-char* *escaped-char* "'")))

(defmacro scan-json-string-internal (re)
  `(let ((start (point)))
     (block scan-json-string-internal
       (while (scan-buffer ,re :tail t :regexp t)
         (when (match-beginning 1) ;; unicode escape
           (replace-match (string
                           (unicode-char
                            (parse-integer (match-string 1) :start 2 :radix 16)))))
         (when (match-beginning 2) ;; escaped char
           (replace-match (cdr (assoc (match-string 2) *json-lisp-escaped-chars*
                                      :test #'string=))))
         (when (match-beginning 3) ;; end of string
           (return-from scan-json-string-internal
             (buffer-substring start (1- (point))))))
       (raise-json-parse-error "unterminated string: ~S"
                               (buffer-substring (1- start) (point-max))))))

(defmacro scan-json-double-quote-string (options)
  `(scan-json-string-internal *re-double-quote-string*))

(defmacro scan-json-single-quote-string (options)
  `(progn
     (when (option-strict ,options)
       (raise-json-parse-error "single quoted string not allowed."))
     (scan-json-string-internal *re-single-quote-string*)))

(defmacro scan-json-string (options)
  `(cond ((skip-char-if #\")
          (scan-json-double-quote-string ,options))
         ((skip-char-if #\')
          (scan-json-single-quote-string ,options))
         (t
          (scan-json-bare-value ,options))))


(defun parse-json-number (value)
  (labels ((raise! (msg)
             (raise-json-parse-error "invalid number: ~S (~A)" value msg))
           (read-number (str)
             (identity (read-from-string str)))
           (convert-double-float (str)
             ;; 3e39 ‚ð 3d39 ‚É‚·‚é
             (substitute #\d #\e str :test #'char-equal))
           (try-read-number (str)
             (handler-case
                 (read-number value)
               (reader-error (c)
                 (handler-case
                     (read-number (convert-double-float value))
                   (reader-error (_)
                     (si:*throw-error c)))))))
    (handler-case
        (let ((n (try-read-number value)))
          (unless (numberp n)
            (raise! "not a number"))
          n)
      (reader-error (c)
        (raise! (reader-error-datum c))))))

(defmacro scan-json-value (options)
  `(case (current-char)
     (#\{ (scan-json-object ,options))
     (#\[ (scan-json-array ,options))
     ((#\" #\') (scan-json-string ,options))
     (t (scan-json-bare-value ,options))))

(defmacro scan-json-object/array (options)
  `(case (current-char)
     (#\{ (scan-json-object ,options))
     (#\[ (scan-json-array ,options))
     ((#\" #\')
      (raise-json-parse-error "unexpected string, expecting object or array."))
     (t
      (raise-json-parse-error "unexpected bare word, expecting object or array."))))

(defun scan-json-object (options)
  (skip-char #\{)
  (skip-ws)
  (let ((obj nil))
    (unless (skip-char-if #\})
      (loop
        (let ((k (scan-json-string options)))
          (skip-ws)
          (skip-char #\:)
          (skip-ws)
          (let ((v (scan-json-value options)))
            (push (cons k v) obj))
          (skip-ws)
          (break-loop-if-char= #\})
          (skip-char #\,)
          (unless (option-strict options)
            (skip-ws)
            (break-loop-if-char= #\}))
          (skip-ws)
          )))
    (if (eq (option-json-object options) :alist)
        (nreverse obj)
      (to-hash obj (option-hash-table-test options)))))

(defun scan-json-array (options)
  (skip-char #\[)
  (skip-ws)
  (let ((obj nil))
    (unless (skip-char-if #\])
      (loop
        (let ((v (scan-json-value options)))
          (push v obj))
        (skip-ws)
        (break-loop-if-char= #\])
        (skip-char #\,)
        (unless (option-strict options)
          (skip-ws)
          (break-loop-if-char= #\]))
        (skip-ws)
        ))
    (if (eq (option-json-array options) :list)
        (nreverse obj)
      (to-array (nreverse obj)))))

(defun scan-json-toplevel (options)
  (goto-char (point-min))
  (if (option-strict options)
      (scan-json-object/array options)
    (progn
      (delete-json-padding)
      (skip-ws)
      (scan-json-value options))))

(defun json-decode (json-text &rest options)
  (check-type json-text string)
  (let ((options (parse-options options)))
    (with-temporary-buffer (*json-decode-buffer-name*)
      (insert json-text)
      (scan-json-toplevel options))))

(defun json-decode-file (filename &rest options)
  (check-type filename string)
  (setf filename (namestring filename))
  (let ((options (parse-options options)))
    (with-temporary-buffer (*json-decode-buffer-name*)
      (read-file filename nil t)
      (scan-json-toplevel options))))


(provide "json/decoder")

;;;; End
