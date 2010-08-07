; -*- mode: lisp; package: json -*-

;;; json/accessor.l
;;
;; Copyright (c) 2010 MIYAMUKO Katsuyuki.
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
  (mc-require "json/package")
  )

(in-package :json)

(export '(json-object-keys
          json-key-p
          json-values
          json-value
          ))

(defun json-object-keys (json)
  (ensure-json-object json)
  (case (type-of json)
    (hash-table
     (loop for k being the hash-keys in json
       collect k))
    (t ;; alist
     (mapcar #'car json))))

(defun json-key-p (json key &key (test 'equal))
  (ensure-json-object json)
  (case (type-of json)
    (hash-table
     (multiple-value-bind (v found)
         (gethash key json)
       found))
    (t ;; alist
     ;; hash-table の場合と結果を合わせるため member の結果をそのまま返さない
     (not (null (member key json :test test :key #'car))))))

#| Example
(in-package :json)
(let ((json (json-decode "{a:{b:{c:[1,2,3], d:[10,20,30]}}, e:[100,200,300]}}}" :strict nil)))
  (multiple-value-bind (c1 d2 e)
      (json-values json `((:a :b :c (lambda (c) (mapcar #'1+ c)))
                          (:a :b :d 2)
                          :e))
    (list c1 d2 e)))

;;=> ((2 3 4) 30 (100 200 300))
|#
(defun json-values (json keys-list &key (test 'equal))
  (values-list (mapcar #'(lambda (keys)
                           (json-value json keys :test test))
                       keys-list)))

(defun json-value (json keys &key (test 'equal))
  (when (atom keys)
    (setf keys (list keys)))
  ;; キーのチェック
  (setf keys (mapcar #'process-keys keys))
  (dolist (key keys)
    (check-type key (or keyword string integer function symbol)))
  (json-value1 json keys test))

(defun json-value1 (json keys test)
  (let ((key (car keys))
        (subkeys (cdr keys)))
    (unless key
      (return-from json-value1 json))
    (let ((v (cond ((or (stringp key) (keywordp key))
                    (cond ((hash-table-p json)
                           ;; gethash に test は指定できない
                           ;; 比較関数は json-decode で指定する :hash-table-test に依存
                           (identity (gethash key json)))
                          ((alistp json)
                           (cdr (assoc key json :test test)))
                          ((listp json)
                           (mapcar #'(lambda (v)
                                       (json-value1 v (list key) test))
                                   json))
                          ((simple-vector-p json)
                           (map 'vector #'(lambda (v)
                                            (json-value1 v (list key) test))
                                json))
                          (t
                           ;; json number or string
                           )))
                   ((integerp key)
                    (if (simple-vector-p json)
                        (when (< key (length json))
                          (elt json key))
                      (nth key json)))
                   (t ;; symbol or function
                    (funcall key json)))))
      (json-value1 v subkeys test))))

(defun process-keys (keys)
  ;; quote の中で関数を書いてしまった場合を救ってあげる。
  ;;   '(:key1 :key2 'parse-integer)
  ;;   '(:key1 :key2 #'parse-integer)
  ;;   '(:key1 :key2 (lambda (v) (parse-integer v)))
  ;; 本来は backquote と , で書くべき。
  (when (and (consp keys)
             (or (eq 'function (car keys))
                 (eq 'quote (car keys))
                 (eq 'lambda (car keys))))
    (setf keys (eval keys)))
  keys)


(provide "json/accessor")

;;; End
