;;;; -*- mode: lisp; package: json -*-
;;;;
;;;; File: json/conditions.l
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

(export '(json-simple-error
          json-parse-error
          ))

(export '(json-simple-error
          json-parse-error
          json-argument-error
          ))

(define-condition json-simple-error (simple-error)
  ()
  (:report (lambda (c s)
             (apply 'format s (json-simple-error-format-string c)
                     (json-simple-error-format-arguments c)))))

(define-condition json-parse-error (json-simple-error)
  ()
  (:report (lambda (c s)
             (apply 'format s (json-parse-error-format-string c)
                     (json-parse-error-format-arguments c)))))

(defun raise-json-parse-error (format-string &rest format-arguments)
  (error 'json-parse-error
         :format-string (concat "json parse error: " format-string)
         :format-arguments format-arguments))


(define-condition json-argument-error (json-simple-error)
  ()
  (:report (lambda (c s)
             (apply 'format s (json-parse-error-format-string c)
                     (json-parse-error-format-arguments c)))))

(defun raise-json-argument-error (format-string &rest format-arguments)
  (error 'json-argument-error
         :format-string (concat "json argument error: " format-string)
         :format-arguments format-arguments))

(defun raise-end-of-json-error (expect)
  (raise-json-parse-error "unexpected end of json, expecting ~A."
                          (if (stringp expect)
                              expect
                            (format nil "'~A'" expect))))


(provide "json/conditions")

;;;; End
