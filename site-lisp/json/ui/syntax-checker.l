; -*- mode: lisp; package: json.ui; encoding: shift_jis -*-

;;; json/ui/syntex-checker.l
;;
;; Copyright (c) 2011 MIYAMUKO Katsuyuki.
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Code:

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "json/package")
  (require "json/decoder")
  )

(in-package :json.ui)

(export '(json-syntax-check-buffer
          json-syntax-check-region
          ))

(defun json-syntax-check-buffer ()
  (interactive)
  (json-syntax-check-region (point-min) (point-max)))

(defun json-syntax-check-region (s e)
  (interactive "r")
  (if (< e s) (rotatef s e))
  (handler-case
      (progn
        (json-decode (buffer-substring s e))
        (popup-string "JSON syntax OK!" (point)))
    (json-parse-error (c)
      (goto-char s)
      (forward-line (- (json-parse-error-linenum c) 1))
      (goto-column (json-parse-error-column c))
      (popup-string (format nil "~A" c) (point))
      )))


(provide "json/ui/syntex-checker")

;;; End
