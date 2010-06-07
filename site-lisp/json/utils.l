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

(defun D0(&rest args)
  (msgbox "~S~%line=~D, col=~D, point=~D~%[~A~A]"
          args
          (current-line-number) (current-column) (point)
          (char-before (point))
          (char-after (point))
          )
  (car (last args)))

(defun re-union (&rest re-list)
  (format nil "~{\\(~A\\)~^\\|~}" re-list))


(provide "json/utils")

;;;; End
