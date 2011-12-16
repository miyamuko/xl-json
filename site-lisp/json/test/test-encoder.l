; -*- mode: lisp; package: json.test.encoder; encoding: shift_jis -*-

;;; json/test/test-encoder.l
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

(require "json")
(require "lisp-unit")

(require "json/test/helper")

(defpackage :json.test.encoder
  (:use :lisp :editor
   :lisp-unit :json.test.helper
   :json
   ))

(in-package :json.test.encoder)

(remove-all-tests :json.test.encoder)

(define-test json-encode/array
  (assert-equal "[]"
      (json-encode '() :json-object :hash-table))
  (assert-equal "[null,[null]]"
      (json-encode '(() (()))))
  (assert-equal "[null,[null]]"
      (json-encode '(() (())) :json-array :list))
  (assert-equal "[[],[[]]]"
      (json-encode '(() (())) :json-null :null :json-false :false))
  (assert-equal "[[],[[]]]"
      (json-encode '(() (())) :json-null :null :json-false :false :json-array :list))
  (assert-equal "[\"bar\",\"baz\"]"
      (json-encode '("bar" "baz")))
  (assert-equal "[{\"bar\":\"baz\"},{\"bar2\":\"baz2\"}]"
      (json-encode '((("bar" . "baz")) (("bar2" . "baz2")))))
  )

(define-test json-encode/array-vector
  (assert-equalp "[]"
      (json-encode (make-vector 0) :json-array :array))
  (assert-equalp "[1,2,3]"
      (json-encode (make-vector 3 :initial-contents '(1 2 3)) :json-array :array))
  (assert-equalp "[[],[]]"
      (json-encode (make-vector 2 :initial-contents (list (make-vector 0) (make-vector 0))
                                :json-array :array)))
  )

(define-test json-encode/object
  (assert-equal "{}"
      (json-encode '() :json-array :array))
  (assert-equal "{\"foo\":\"bar\"}"
      (json-encode '(("foo" . "bar")) :json-object :alist))
  (assert-equal "{\"foo\":\"bar\",\"foo2\":\"bar2\"}"
      (json-encode '(("foo" . "bar") ("foo2" . "bar2"))))
  (assert-equal "{\"foo\":\"bar\"}"
      (json-encode '(("foo" . "bar")) :json-object :alist))
  )


(define-test json-encode/object-hash-table
  (assert-equalp "{}"
      (json-encode (make-hash-table :test 'equal) :json-object :hash-table))
  (assert-equalp "{\"foo\":\"bar\"}"
      (json-encode (let ((h (make-hash-table :test 'equal)))
                     (setf (gethash "foo" h) "bar")
                     h) :json-object :hash-table))
  )

(define-test json-encode/null
  (assert-equal "[null]"
      (json-encode '(nil)))
  (assert-equal "[null]"
      (json-encode '(:null) :json-null :null))
  (assert-equal "[{\"foo\":null}]"
      (json-encode '((("foo" . :null))) :json-null (intern "null" :keyword)))
  )

(define-test json-encode/true
  (assert-equal "[true]"
      (json-encode '(t)))
  (assert-equal "[true]"
      (json-encode '(:true) :json-true :true))
  (assert-equal "[{\"foo\":true}]"
      (json-encode '((("foo" . :true))) :json-true (intern "true" :keyword)))
  )

(define-test json-encode/false
  (assert-equal "[false]"
      (json-encode '(nil) :json-null :null))
  (assert-equal "[false]"
      (json-encode '(:false) :json-false :false))
  (assert-equal "[{\"foo\":false}]"
      (json-encode '((("foo" . :false))) :json-false (intern "false" :keyword)))
  )

(define-test json-encode/string
  (assert-equal "[\"\"]"
      (json-encode '("")))
  (assert-equal "[\"foo\"]"
      (json-encode '("foo")))
  (assert-equal "[\"foo bar\"]"
      (json-encode '("foo bar")))
  (let ((long-string (make-sequence 'string 100000 :initial-element #\a)))
    (assert-equal (format nil "[\"~A\"]" long-string)
        (json-encode (list long-string))))
  )

(define-test json-encode/string-escape
  (assert-equal "[\"\\\"\\\\\\/\\b\\f\\n\\r\\t\"]"
      (json-encode '("\"\\\/\b\f\n\r\t")))
  (assert-equal "[\"foo\\nbar\"]"
      (json-encode '("foo\nbar")))
  (assert-equal "[\"foo\\tbar\"]"
      (json-encode '("foo\tbar")))
  (assert-equal "[\"foo\\t\"]"
      (json-encode '("foo\t")))
  (assert-equal "[\"\\\"foo\\\"\"]"
      (json-encode '("\"foo\"")))
  )


(define-test json-encode/string-unicode
  (assert-equal "[\"\\u3042\"]"
      (json-encode '("あ")))
  (assert-equal "[\"\\u3042\\u3044\\u3046\\u3048\\u304aabc\\u30a2\\u30a4\\u30a6\\u30a8\\u30aa\"]"
      (json-encode '("あいうえおabcアイウエオ")))
  (assert-equal "[\"\\u306f\\u3066\\u306a\\u30b9\\u30bf\\u30fc\\u65e5\\u8a18\"]"
      (json-encode '("はてなスター日記")))

  ;; #\latin_capital_letter_a_with_acute                => #\x0141
  ;; (char-unicode #\latin_capital_letter_a_with_acute) => 193 (U+00C1)
  (assert-equal "[\"\\u00c1\"]"
      (json-encode '("\X0141")))

  ;; To escape an extended character that is not in the Basic Multilingual
  ;; Plane, the character is represented as a twelve-character sequence,
  ;; encoding the UTF-16 surrogate pair.  So, for example, a string
  ;; containing only the G clef character (U+1D11E) may be represented as
  ;; "\uD834\uDD1E".
  (assert-equal "[\"\\ud834\\udd1e\"]"
      (json:json-encode (list (string (unicode-char #x1D11E)))))
  )

(define-test json-encode/character
  (assert-equal "[\"a\"]"
      (json-encode '(#\a)))
  (assert-equal "[\"a\",\"b\"]"
      (json-encode '(#\a #\b)))
  )

(define-test json-encode/character-escape
  (assert-equal "[\"\\\"\",\"\\\\\",\"\\/\",\"\\b\",\"\\f\",\"\\n\",\"\\r\",\"\\t\"]"
      (json-encode '(#\" #\\ #\/ #\C-h #\C-l #\LFD #\RET #\TAB)))
  )


(define-test json-encode/character-unicode
  (assert-equal "[\"\\u3042\"]"
      (json-encode '(#\あ)))
  (assert-equal "[\"\\u3042\",\"\\u3044\",\"\\u3046\",\"\\u3048\",\"\\u304a\",\"a\",\"b\",\"c\",\"\\u30a2\",\"\\u30a4\",\"\\u30a6\",\"\\u30a8\",\"\\u30aa\"]"
      (json-encode '(#\あ #\い #\う #\え #\お #\a #\b #\c #\ア #\イ #\ウ #\エ #\オ)))

  ;; #\latin_capital_letter_a_with_acute                => #\x0141
  ;; (char-unicode #\latin_capital_letter_a_with_acute) => 193 (U+00C1)
  (assert-equal "[\"\\u00c1\"]"
      (json-encode '(#\latin_capital_letter_a_with_acute)))
  )

(define-test json-encode/number-integer
  (assert-equal "{\"foo\":1}"
      (json-encode '(("foo" . 1))))
  (assert-equal "{\"foo\":2,\"foo2\":3.3}"
      (json-encode '(("foo" . 2) ("foo2" . 3.3))))
  (assert-equalp "[0,1,2,10,-1,-2,-10]"
      (json-encode '(0 1 2 10 -1 -2 -10)))
  (assert-equalp "[15,585,4369]"
      (json-encode '(#b1111 #o1111 #x1111)))
  )

(define-test json-encode/number-float
  (assert-equal "[1,0.11,1.11,11.11,-1,-0.11,-1.11,-11.11]"
      (json-encode '(1 0.11 1.11 11.11 -1 -0.11 -1.11 -11.11)))
  )

(define-test json-encode/number-scientific-notation
  (assert-equal "[1.0e10,-1.0e10,-1.0e-10]"
      (json-encode '(1e10 -1e10 -1e-10)))
  )

(define-test json-encode/number-scientific-notation-double
  ;; most-positive-double-float => 1.797693134862316d308
  ;; most-positive-single-float => 3.402823e38

  (assert-equal "[3.402822e38]"
      (json-encode '(3.402822e38)))
  (assert-equal "[3.402822e39]"
      (json-encode '(3.402822d39)))
  (assert-equal "[1.797693134862315e308]"
      (json-encode '(1.797693134862315d308)))
  )

(define-test json-encode/not-supported-type
  (assert-error 'json-argument-error
      (json-encode '(1/3)))
  (assert-error 'json-argument-error
      (json-encode '(#C(5 3))))
  )
