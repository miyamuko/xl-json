;;;; -*- mode: lisp; package: json -*-
;;;;
;;;; File: json/macros.l
;;;;
;;;; License:
;;;;
;;;;   Copyright (c) 2008,2010 MIYAMUKO Katsuyuki.
;;;;
;;;;   json is released under an MIT license.
;;;;   See json/docs/MIT-LICENSE for full license.
;;;;

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "json/package")
  )

(in-package :json)

(defmacro with-gensyms (syms &body body)
  `(let ,(mapcar #'(lambda (sym)
                     `(,sym (gensym)))
                 syms)
     ,@body))
(setf (get 'with-gensyms 'ed:lisp-indent-hook) 'let)

(defmacro save-current-buffer (&body body)
  (with-gensyms (original)
    `(let ((,original (selected-buffer)))
       (with-set-buffer
         (unwind-protect
             (progn ,@body)
           (unless (deleted-buffer-p ,original)
             (set-buffer ,original)))))))
(setf (get 'save-current-buffer 'ed:lisp-indent-hook) 'save-excursion)

(defmacro with-temporary-buffer ((name) &body body)
  (with-gensyms (tmp)
    `(save-current-buffer
       (let ((,tmp (get-buffer-create ,name)))
         (unwind-protect
             (with-set-buffer
               (set-buffer ,tmp)
               (erase-buffer ,tmp)
               ,@body)
           (unless (deleted-buffer-p ,tmp)
             (erase-buffer ,tmp)))))))
(setf (get 'with-temporary-buffer 'ed:lisp-indent-hook) 'with-set-buffer)


(defmacro to-array (list)
  (with-gensyms (glist)
    `(let ((,glist ,list))
       (make-vector (length ,glist) :initial-contents ,glist))))

(defmacro to-hash (alist hash-table-test)
  (with-gensyms (galist)
    `(let ((,galist ,alist))
       (let ((r (make-hash-table
                 :size (length ,galist)
                 :test ,hash-table-test)))
         (dolist (pair ,galist)
           (setf (gethash (car pair) r) (cdr pair)))
         r))))



(defmacro puts (fmt &rest args)
  `(format t ,fmt ,@args))

(defmacro write-each (map-fn fn object &optional prefix suffix infix)
  `(let ((first t))
     ,(when prefix
        `(puts ,(format nil "~A" prefix)))
     (,map-fn
             #'(lambda (&rest args)
                 (if first
                     (setf first nil)
                   ,(when infix
                      `(puts ,(format nil "~A" infix))))
                 (apply ,fn args))
      ,object)
     ,(when suffix
        `(puts ,(format nil "~A" suffix)))
    ))


(provide "json/macros")

;;;; End
