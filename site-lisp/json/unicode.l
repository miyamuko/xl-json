;;;; -*- mode: lisp; package: json -*-
;;;;
;;;; File: json/unicode.l
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

#|
See src/charset.h

(unicode-char #X3042)       ;=> #\‚ 
(unicode-char #Xfffd)       ;=> "\Xd6ff\Xd7fd"
(undef-char-high-p #Xd6ff)  ;=> t
(undef-char-low-p #Xd7fd)   ;=> t
(combine-undef-char
 (undef-char-high #Xd6ff)
 (undef-char-low #Xd7fd))   ;=> #Xfffd
|#

(defconstant CCS_UTF16_UNDEF_CHAR_HIGH    #xd600)
(defconstant CCS_UTF16_UNDEF_CHAR_LOW     #xd700)

(defun undef-char-high-p (code)
  (= CCS_UTF16_UNDEF_CHAR_HIGH (logand (lognot #xFF) code)))

(defun undef-char-low-p (code)
  (= CCS_UTF16_UNDEF_CHAR_LOW (logand (lognot #xFF) code)))

(defun undef-char-high (code)
  (when (undef-char-high-p code)
    (logand (lognot CCS_UTF16_UNDEF_CHAR_HIGH) code)))

(defun undef-char-low (code)
  (when (undef-char-low-p code)
    (logand (lognot CCS_UTF16_UNDEF_CHAR_LOW) code)))

(defun combine-undef-char (high low)
  (logior (ash high 8) low))


(provide "json/unicode")

;;; End
