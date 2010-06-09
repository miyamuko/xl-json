;;;; -*- mode: lisp; package: json -*-
;;;;
;;;; File: json/amacros.l
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

(defmacro acond (&rest forms)
  `(let (_it_)
     (cond ,@(mapcar #'(lambda (form)
                         `((setf _it_ (progn ,(car form)))
                           ,@(cdr form)))
                     forms))))


(provide "json/amacros")

;;; End
