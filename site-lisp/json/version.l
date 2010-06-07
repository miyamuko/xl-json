;;;; -*- mode: lisp; package: json -*-
;;;;
;;;; File: json/version.l
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

(export '(json-version
          ))

(defconstant +json-version+ "0.1.2")

(defun json-version ()
  +json-version+)


(provide "json/version")

;;;; End
