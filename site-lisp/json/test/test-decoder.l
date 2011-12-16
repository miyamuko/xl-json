; -*- mode: lisp; package: json.test.decoder; encoding: shift_jis -*-

;;; json/test/test-decoder.l
;;
;; Copyright (c) 2010-2011 MIYAMUKO Katsuyuki.
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

(defpackage :json.test.decoder
  (:use :lisp :editor
   :lisp-unit :json.test.helper
   :json
   ))

(in-package :json.test.decoder)

(remove-all-tests :json.test.decoder)

(define-test json-decode/array
  (assert-equal '()
      (json-decode "[]"))
  (assert-equal '(() (()))
      (json-decode "[[],[[]]]"))
  (assert-equal '(() (()))
      (json-decode "[[],[[]]]" :json-array :list))
  (assert-equal '("bar" "baz")
      (json-decode "[\"bar\",\"baz\"]"))
  (assert-equal '((("bar" . "baz")) (("bar2" . "baz2")))
      (json-decode "[{\"bar\":\"baz\"},{\"bar2\":\"baz2\"}]"))
  )

(define-test json-decode/array-vector
  (assert-type array (json-decode "[]" :json-array :array))
  (assert-equalp (make-vector 0)
      (json-decode "[]" :json-array :array))
  (assert-equalp (make-vector 3 :initial-contents '(1 2 3))
      (json-decode "[1, 2, 3]" :json-array :array))
  )

(define-test json-decode/object
  (assert-equal '()
      (json-decode "{}"))
  (assert-equal '(("foo" . "bar"))
      (json-decode "{\"foo\":\"bar\"}" :json-object :alist))
  (assert-equal '(("foo" . "bar") ("foo2" . "bar2"))
      (json-decode "{\"foo\":\"bar\",\"foo2\":\"bar2\"}"))
  (assert-equal '(("foo" . "bar"))
      (json-decode "{
\"foo\"
:
\"bar\"
}" :json-object :alist))
  )

(define-test json-decode/object-hash-table
  (assert-type hash-table (json-decode "{}" :json-object :hash-table))
  (assert-equalp (make-hash-table :test 'equal)
      (json-decode "{}" :json-object :hash-table))
  (assert-equalp (let ((h (make-hash-table :test 'equal)))
                   (setf (gethash "foo" h) "bar")
                   h)
      (json-decode "{\"foo\":\"bar\"}" :json-object :hash-table))
  )

(define-test json-decode/object-hash-table-test
  (dolist (test '(eq eql equal equalp))
    (assert-equal test
        (hash-table-test (json-decode "{}" :json-object :hash-table :hash-table-test test))))

  (let ((h (json-decode "{\"foo\":123}" :json-object :hash-table)))
    (assert-equal 123 (gethash "foo" h))
    (assert-equal nil (gethash "FOO" h)))

  (let ((h (json-decode "{\"foo\":123}" :json-object :hash-table :hash-table-test #'equalp)))
    (assert-equal 123 (gethash "FOO" h))
    (assert-equal 123 (gethash "FOO" h)))
  )

(define-test json-decode/null
  (assert-equal '(nil)
      (json-decode "[null]"))
  (assert-equal '(:null)
      (json-decode "[null]" :json-null :null))
  (assert-equal '((("foo" . :null)))
      (json-decode "[{\"foo\":null}]" :json-null (intern "null" :keyword)))
  )

(define-test json-decode/true
  (assert-equal '(t)
      (json-decode "[true]"))
  (assert-equal '(:true)
      (json-decode "[true]" :json-true :true))
  (assert-equal '((("foo" . :true)))
      (json-decode "[{\"foo\":true}]" :json-true (intern "true" :keyword)))
  )

(define-test json-decode/false
  (assert-equal '(nil)
      (json-decode "[false]"))
  (assert-equal '(:false)
      (json-decode "[false]" :json-false :false))
  (assert-equal '((("foo" . :false)))
      (json-decode "[{\"foo\":false}]" :json-false (intern "false" :keyword)))
  )

(define-test json-decode/string
  (assert-equal '("")
      (json-decode "[\"\"]"))
  (assert-equal '("foo")
      (json-decode "[\"foo\"]"))
  (assert-equal '("foo bar")
      (json-decode "[\"foo bar\"]"))
  (let ((long-string (make-sequence 'string 100000 :initial-element #\a)))
    (assert-equal (list long-string)
        (json-decode (format nil "[\"~A\"]" long-string))))
  )

(define-test json-decode/string-escape
  (assert-equal '("\"\\\/\b\f\n\r\t")
      (json-decode "[\"\\\"\\\\\\/\\b\\f\\n\\r\\t\"]"))
  (assert-equal '("foo\nbar")
      (json-decode "[\"foo\\nbar\"]"))
  (assert-equal '("foo\tbar")
      (json-decode "[\"foo\\tbar\"]"))
  (assert-equal '("foo\t")
      (json-decode "[\"foo\\t\"]"))
  (assert-equal '("\"foo\"")
      (json-decode "[\"\\\"foo\\\"\"]"))
  )

(define-test json-decode/string-escape/invalid-sequence
  (assert-error 'json-parse-error
      (json-decode "[\"abc\\w\\z\"]" :strict t))
  (assert-error 'json-parse-error
      (json-decode "[\"abc\\w\\z\"]" :strict nil))
  )

(define-test json-decode/string-unicode
  (assert-equal '("あ")
      (json-decode "[\"あ\"]"))
  (assert-equal '("あ")
      (json-decode "[\"\\u3042\"]"))
  (assert-equal '("あいうえおabcアイウエオ")
      (json-decode "[\"\\u3042\\u3044\\u3046\\u3048\\u304Aabc\\u30A2\\u30A4\\u30A6\\u30A8\\u30AA\"]"))
  (assert-equal '("はてなスター日記")
      (json-decode "[\"\\u306f\\u3066\\u306a\\u30b9\\u30bf\\u30fc\\u65e5\\u8a18\"]"))

  ;; #\latin_capital_letter_a_with_acute                => #\x0141
  ;; (char-unicode #\latin_capital_letter_a_with_acute) => 193 (U+00C1)
  (assert-equal '("\X0141" "\X0141")
      (json-decode "[\"\\u00C1\", \"\\u00c1\"]"))

  ;; To escape an extended character that is not in the Basic Multilingual
  ;; Plane, the character is represented as a twelve-character sequence,
  ;; encoding the UTF-16 surrogate pair.  So, for example, a string
  ;; containing only the G clef character (U+1D11E) may be represented as
  ;; "\uD834\uDD1E".
  (assert-equal (list (string (unicode-char #x1D11E)))
      (json:json-decode "[\"\\uD834\\uDD1E\"]"))
  )

(define-test json-decode/string-unicode/invalid-sequence
  (assert-error 'json-parse-error
      (json-decode "[\"\\u2\"]"))
  (assert-error 'json-parse-error
      (json-decode "[\"\\u20\"]"))
  (assert-error 'json-parse-error
      (json-decode "[\"\\u020\"]"))

  (assert-equal '(" ")
      (json-decode "[\"\\u0020\"]"))
  (assert-equal '(" a")
      (json-decode "[\"\\u0020a\"]"))
  (assert-equal '(" abcdef")
      (json-decode "[\"\\u0020abcdef\"]"))
  )

(define-test json-decode/number-integer
  (assert-equal '(("foo" . 1))
      (json-decode "{\"foo\":1}"))
  (assert-equal '(("foo" . 2) ("foo2" . 3.3))
      (json-decode "{\"foo\":2,\"foo2\":3.3}"))
  (assert-equalp '(0 1 2 10 -1 -2 -10)
      (json-decode "[0,1,2,10,-1,-2,-10]")))

(define-test json-decode/number-float
  (dolist (pair (mapcar #'cons
                        '(1 0.11 1.11 11.11
                          -1 -0.11 -1.11 -11.11)
                        (json-decode "[
 1,  0.11,  1.11,  11.11,
-1, -0.11, -1.11, -11.11]")))
    (assert-double-equalp (car pair) (cdr pair)))
  )

(define-test json-decode/number-scientific-notation
  (dolist (pair (mapcar #'cons
                        '(
 1e+1   0.11e+1   1.11e+1   11.11e+1
-2e+1  -2.11e+1  -2.11e+1  -12.11e+1
 3e-1   3.11e-1   3.11e-1   13.11e-1
-4e-1  -4.11e-1  -4.11e-1  -14.11e-1
 5e10   5.15e10   5.11e10   15.11e10
-6e10  -6.16e10  -6.11e10  -16.11e10
 7e+10  7.17e+10  7.11e+10  17.11e+10
-8e+10 -8.18e+10 -8.11e+10 -18.11e+10
 9e-10  9.19e-10  9.11e-10  19.11e-10
-1e-10 -0.11e-10 -1.11e-10 -11.11e-10
                          )
                        (json-decode "[
 1e+1,   0.11e+1,   1.11e+1,   11.11e+1,
-2e+1,  -2.11e+1,  -2.11e+1,  -12.11e+1,
 3e-1,   3.11e-1,   3.11e-1,   13.11e-1,
-4e-1,  -4.11e-1,  -4.11e-1,  -14.11e-1,
 5e10,   5.15e10,   5.11e10,   15.11e10,
-6e10,  -6.16e10,  -6.11e10,  -16.11e10,
 7e+10,  7.17e+10,  7.11e+10,  17.11e+10,
-8e+10, -8.18e+10, -8.11e+10, -18.11e+10,
 9e-10,  9.19e-10,  9.11e-10,  19.11e-10,
-1e-10, -0.11e-10, -1.11e-10, -11.11e-10
]")))
    (assert-double-equalp (car pair) (cdr pair)))
  )

(define-test json-decode/number-scientific-notation-double
  ;; most-positive-double-float => 1.797693134862316d308
  ;; most-positive-single-float => 3.402823e38

  (assert-double-equalp 3.402822e38 (car (json-decode "[3.402822e38]")))
  (assert-double-equalp 3.402822e38 (car (json-decode "[3.402822e38]")))
  (assert-type single-float (car (json-decode "[3.402822e38]")))

  (assert-double-equalp 3.402822d39 (car (json-decode "[3.402822E39]")))
  (assert-double-equalp 3.402822d39 (car (json-decode "[3.402822E39]")))
  (assert-type double-float (car (json-decode "[3.402822e39]")))

  (assert-double-equalp 1.797693134862315d308 (car (json-decode "[1.797693134862315e308]")))
  (assert-double-equalp 1.797693134862315d308 (car (json-decode "[1.797693134862315E308]")))
  (assert-type double-float (car (json-decode "[1.797693134862315E308]")))

  (assert-error 'json-parse-error
      (json-decode "[1.797693134862316e308]"))
  (assert-error 'json-parse-error
      (json-decode "[1.797693134862316E308]"))
  )


(define-test json-decode/no-strict-bare-string
  (assert-error 'json-parse-error
      (json-decode "{foo:bare}" :strict t))
  (assert-equal '(("foo" . "bare"))
      (json-decode "{foo:bare}" :strict nil))
  (assert-equal '(("foo" . "bare"))
      (json-decode "{\"foo\":bare}" :strict nil))
  (assert-equal '(("foo" . t) ("bar" . nil) ("baz" . nil))
      (json-decode "{
foo : true,
bar: false ,
baz: null  }" :strict nil))
  )

(define-test json-decode/no-strict-single-quote-string
  (assert-error 'json-parse-error
      (json-decode "{'foo':'bar'}" :strict t))
  (assert-equal '(("foo" . "bar"))
      (json-decode "{'foo':'bar'}" :strict nil))
  (assert-error 'json-parse-error
      (json-decode "{'foo':\"bar\"}" :strict t))
  (assert-equal '(("foo" . "bar"))
      (json-decode "{'foo':\"bar\"}" :strict nil))
  )

(define-test json-decode/no-strict-extra-comma
  (assert-error 'json-parse-error
      (json-decode "{\"lang\":[\"lisp\",\"ruby\",],}" :strict t))
  (assert-equal '(("lang" . ("lisp" "ruby")))
      (json-decode "{\"lang\":[\"lisp\",\"ruby\",],}" :strict nil))
  )

(define-test json-decode/no-strict-toplevel-value
  (assert-equal "foo" (json-decode "\"foo\"" :strict nil))
  (assert-equal "foo" (json-decode "foo" :strict nil))
  (assert-equal t (json-decode "true" :strict nil))
  (assert-equal 123 (json-decode "123" :strict nil))

  (assert-equal :jnull (json-decode "null)" :strict nil :json-null :jnull))
  (assert-equal :jnull (json-decode "(null" :strict nil :json-null :jnull))
  (assert-equal :jnull (json-decode "(null)" :strict nil :json-null :jnull))
  (assert-equal :jtrue (json-decode "foo(true)" :strict nil :json-true :jtrue))
  (assert-equal :jtrue (json-decode "foo(true" :strict nil :json-true :jtrue))
  (assert-equal :jtrue (json-decode "true)" :strict nil :json-true :jtrue))
  )

(define-test json-decode/no-strict-padding
  (assert-equal '(1 2 t)
      (json-decode "([1,2,true])" :strict nil))
  (assert-equal '(1 2 t)
      (json-decode "Ten.JSONP([1,2,true])" :strict nil))
  (assert-equal :jtrue
      (json-decode "Ten.JSONP(true)" :strict nil :json-true :jtrue))
  (assert-equal :jtrue
      (json-decode "$F(true)" :strict nil :json-true :jtrue))
  (assert-equal :jtrue
      (json-decode "$$(true)" :strict nil :json-true :jtrue))
  (assert-equal '((1 . 2))
      (json-decode "foo({1:2})" :strict nil))
  )

(define-test json-decode/leading-whitespace
  (assert-equal '(("foo" . "bar"))
      (json-decode " {\"foo\":\"bar\"}" :strict t))
  (assert-equal '(("foo" . "bar"))
      (json-decode "  {\"foo\":\"bar\"}  " :strict t))
  (assert-equal '(("foo" . "bar"))
      (json-decode "  {  \"foo\"  :  \"bar\"  }  " :strict t))

  (assert-equal '(("foo" . "bar"))
      (json-decode " {\"foo\":\"bar\"}" :strict nil))
  (assert-equal '(("foo" . "bar"))
      (json-decode "  {\"foo\":\"bar\"}  " :strict nil))
  (assert-equal '(("foo" . "bar"))
      (json-decode "  {  \"foo\"  :  \"bar\"  }  " :strict nil))
  (assert-equal '(("foo" . "bar"))
      (json-decode "  Ten.JSONP({  \"foo\"  :  \"bar\"  })  " :strict nil))
  )

(define-test json-decode/error
  (assert-error 'json-argument-error
      (json-decode "{}" :strict nil :json-object t))
  (assert-error 'json-argument-error
      (json-decode "{}" :strict nil :json-object nil))
  (assert-error 'json-argument-error
      (json-decode "{}" :strict nil :json-object :list))

  (assert-error 'json-parse-error
      (json-decode "" :strict t))
  (assert-error 'json-parse-error
      (json-decode "[1,2,3,]" :strict t))
  (assert-error 'json-parse-error
      (json-decode "[  1  ,  2 , 3 , ]" :strict t))
  (assert-error 'json-parse-error
      (json-decode "[1,2,3,,]" :strict nil))

  (assert-error 'json-parse-error
      (json-decode "{"))
  (assert-error 'json-parse-error
      (json-decode "}"))
  (assert-error 'json-parse-error
      (json-decode "{:}"))
  (assert-error 'json-parse-error
      (json-decode "{foo:}"))
  (assert-error 'json-parse-error
      (json-decode "{\"foo\":}"))
  (assert-error 'json-parse-error
      (json-decode "{\"foo\":bare}"))
  (assert-error 'json-parse-error
      (json-decode "{\"foo\":\"bare\",}"))

  (assert-error 'type-error
      (json-decode nil))
  (assert-error 'type-error
      (json-decode-file nil))
  (assert-error 'simple-error
      (json-decode-file ""))
  (assert-error 'simple-error
      (json-decode-file "no such file"))
  )

;; example.json を S 式にしたもの
;; example.json は http://json.org/example.html から作成
(defconstant +json-example-sexp+
  '(("glossary"
     ("title" . "example glossary")
     ("GlossDiv"
      ("title" . "S")
      ("GlossList"
       ("GlossEntry"
        ("ID" . "SGML")
        ("SortAs" . "SGML")
        ("GlossTerm" . "Standard Generalized Markup Language")
        ("Acronym" . "SGML")
        ("Abbrev" . "ISO 8879:1986")
        ("GlossDef" .
         (("para" . "A meta-markup language, used to create markup languages such as DocBook.")
          ("GlossSeeAlso" "GML" "XML")))
        ("GlossSee" . "markup")))))))

(define-test json-decode-file/json-org-example
  (assert-equalp +json-example-sexp+
      (json-decode-file "example.json"))
  )

(define-test json-decode-file/hatebu
  (assert-equal "1715"
      (cdr (assoc "count" (json-decode-file "hatebu.json" :strict nil)
                  :test #'equal)))
  )

(define-test json-decode-buffer
  (let ((b (get-buffer-create "*json:test*")))
    (unwind-protect
        (json::save-current-buffer
          (set-buffer b)
          (insert-file-contents "example.json")
          (assert-equalp +json-example-sexp+
              (json-decode-buffer "*json:test*"))
          (assert-equalp +json-example-sexp+
              (json-decode-buffer (find-buffer "*json:test*")))
          )
      (delete-buffer b)))
  )

(define-test json-decode-buffer/read-only
  (let ((b (get-buffer-create "*json:test*")))
    (unwind-protect
        (progn
          (json::save-current-buffer
            (set-buffer b)
            (insert-file-contents "example.json")
            (toggle-read-only t))
          (assert-equalp +json-example-sexp+
              (json-decode-buffer "*json:test*"))
          (assert-equalp +json-example-sexp+
              (json-decode-buffer (find-buffer "*json:test*")))
          )
      (delete-buffer b)))
  )

(define-test json-decode-buffer/error
  (assert-error 'type-error
      (json-decode-buffer nil))
  (assert-error 'type-error
      (json-decode-buffer 123))

  ;; 存在しないバッファ
  (assert-error 'simple-error
      (json-decode-buffer "*no such buffer*"))

  ;; 削除されたバッファ
  (let ((b (create-new-buffer "*test*")))
    (delete-buffer b)
    (assert-error 'simple-error
        (json-decode-buffer b)))
  )
