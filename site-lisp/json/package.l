;;;; -*- mode: lisp; package: user -*-
;;;;
;;;; File: json/package.l
;;;;
;;;; License:
;;;;
;;;;   Copyright (c) 2008 MIYAMUKO Katsuyuki.
;;;;
;;;;   json is released under an MIT license.
;;;;   See json/docs/MIT-LICENSE for full license.
;;;;

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :json)
    (defpackage :json
      (:use
       :lisp
       :editor
       )))
  (unless (find-package :json.ui)
    (defpackage :json.ui
      (:use
       :lisp
       :editor
       :json
       ))
    (use-package :json.ui :user)
    )
  )


(provide "json/package")

;;;; End
