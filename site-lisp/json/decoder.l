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
          json-decode-buffer
          ))

(defparameter *json-decode-buffer-name* " *json:decode*")

(defmacro skip-ws ()
  `(skip-chars-forward " \t\r\f\n"))

(defmacro narrow-to-json ()
  `(let ((end (if (eq (char-before (point-max)) #\))
                  (- (point-max) 1)
                (point-max)))
         (start (progn
                  (goto-char (point-min))
                  (if (looking-at "[^(){}:,\"']*(")
                      (match-end 0)
                    (point-min)))))
     (narrow-to-region start end)))

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
  `(and (looking-at "[^][{}:,'\" \t\r\f\n]+")
        (match-string 0)))

(defun scan-json-bare-value (options)
  (let ((word (current-bare-word)))
    (unless word
      (raise-if-eobp "json value")
      (raise-json-parse-error "unexpected '~A', expecting json value."
                              (current-char)))
    (prog1
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
                 (raise-json-parse-error "bare word, ~S, not allowed." word))
               word))
      (forward-char (length word)))))

(defparameter *unicode-char* "\\\\u[a-fA-F0-9]\\{4\\}")
(defparameter *escaped-char* "\\\\.")
(defparameter *re-double-quote-string*
  (compile-regexp (re-union *unicode-char* *escaped-char* "\"")))
(defparameter *re-single-quote-string*
  (compile-regexp (re-union *unicode-char* *escaped-char* "'")))

(defmacro scan-json-string-internal (quote-char re)
  `(progn
     (skip-char ,quote-char)
     (let ((start (point))
           (last-match (point))
           r)
       (block scan-json-string-internal
         (while (scan-buffer ,re :tail t :regexp t)
           (push (buffer-substring last-match (match-beginning 0)) r)
           (cond ((match-beginning 1) ;; unicode escape
                  (push (string
                         (unicode-char
                          (parse-integer (match-string 1) :start 2 :radix 16)))
                        r))
                 ((match-beginning 2) ;; escaped char
                  (push (cdr (assoc (match-string 2) *json-lisp-escaped-chars*
                                    :test #'string=))
                        r))
                 ((match-beginning 3) ;; end of string
                  (return-from scan-json-string-internal
                    (format nil "~{~A~}" (nreverse r)))))
           (setf last-match (match-end 0)))
         ;; ÉJÉâÉÄî‘çÜÇçáÇÌÇπÇÈÇΩÇﬂ (skip-char quote-char) ÇµÇΩï™ñﬂÇÈ
         (backward-char)
         (raise-json-parse-error "unterminated string: ~S"
                                 (buffer-substring (1- start) (point-max)))))))

(defmacro scan-json-double-quote-string (options)
  `(scan-json-string-internal #\" *re-double-quote-string*))

(defmacro scan-json-single-quote-string (options)
  `(progn
     (when (option-strict ,options)
       (raise-json-parse-error "single quoted string not allowed."))
     (scan-json-string-internal #\' *re-single-quote-string*)))

(defmacro scan-json-string (options)
  `(cond ((current-char= #\")
          (scan-json-double-quote-string ,options))
         ((current-char= #\')
          (scan-json-single-quote-string ,options))
         (t
          (scan-json-bare-value ,options))))


(defun parse-json-number (value)
  (labels ((raise! (msg)
             (raise-json-parse-error "invalid number: ~S (~A)" value msg))
           (read-number (str)
             (identity (read-from-string str)))
           (convert-double-float (str)
             ;; 3e39 Ç 3d39 Ç…Ç∑ÇÈ
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
      (raise-if-eobp "object or array")
      (raise-json-parse-error "unexpected bare word, ~S, expecting object or array." (current-bare-word)))))

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
      (progn
        (skip-ws)
        (scan-json-object/array options))
    (save-restriction
      (narrow-to-json)
      (skip-ws)
      (scan-json-value options))))

(defun json-decode (json-text &rest options)
  (check-type json-text string)
  (json-decode-internal #'(lambda ()
                            (insert json-text))
                        nil options))

(defun json-decode-file (filename &rest options)
  (check-type filename string)
  (setf filename (namestring filename))
  (json-decode-internal #'(lambda ()
                            (read-file filename nil t))
                        filename options))

(defun json-decode-buffer (buffer &rest options)
  (check-type buffer (or string buffer))
  (json-decode-internal #'(lambda ()
                            (insert (save-current-buffer
                                      (set-buffer buffer)
                                      (buffer-substring (point-min) (point-max)))))
                        (if (bufferp buffer)
                            (buffer-name buffer)
                          buffer)
                        options))

(defun json-decode-internal (initializer src options)
  (let ((options (parse-options options)))
    (with-temporary-buffer (*json-decode-buffer-name*)
      (funcall initializer)
      (set-buffer-alternate-file-name src)
      (unwind-protect
          (scan-json-toplevel options)
        (set-buffer-alternate-file-name nil)))))


(provide "json/decoder")

;;;; End
