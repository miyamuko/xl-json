(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "json")
  )

(defun fail0 (fmt &rest args)
  (message-box (apply 'format (append (list nil fmt) args)) "Error" '(:exclamation))
  (plain-error fmt args))

(defun fail (expect-sexp expect actual)
  (fail0 "~S~%expected ~S,~%  but was ~S"
         expect-sexp expect actual))

(defun hashtable->alist (hash)
  (unless (hash-table-p hash)
    (fail0 "~S is not hashtable." hash))
  (let (r)
    (maphash #'(lambda (k v)
                 (push (cons k v) r))
             hash)
    (sort r #'string< :key 'car)))

(defun vector->list (vec)
  (unless (vectorp vec)
    (fail0 "~S is not vector." vec))
  (let (r)
    (dotimes (i (length vec))
      (push (aref vec i) r))
    (reverse r)))

(defmacro assert (expect actual)
  `(handler-case
       (let ((act ,actual)
             (exp ,expect))
         (unless (equal act exp)
           (fail ',actual exp act)))
     (error (c)
       (fail ',actual ,expect c))))

(defmacro assert-hashtable (expect actual)
  `(handler-case
       (let ((act (hashtable->alist ,actual))
             (exp (hashtable->alist ,expect)))
         (unless (equal act exp)
           (fail ',actual exp act))
         (unless (equal (hash-table-test ,actual)
                        (hash-table-test ,expect))
           (fail0 "~S~%hash-table-test mismatch: ~S but was ~S"
                  ',actual (hash-table-test ,actual) (hash-table-test ,expect))))
     (error (c)
       (fail ',actual ,expect c))))

(defmacro assert-vector (expect actual)
  `(handler-case
       (let ((act (vector->list ,actual))
             (exp (vector->list ,expect)))
         (unless (equal act exp)
           (fail ',actual exp act)))
     (error (c)
       (fail ',actual ,expect c))))

(defmacro assert-raise (expect &body body)
  `(handler-case
       (progn ,@body
         (fail0 "expected raise ~S, but was no error" ',expect))
     (,expect (c)
      (msgbox "~S~% expeted?~%~A" ',body c))
     (error (c)
       (fail0 "expected raise ~S, but was thrown~%~A" ',expect c))
     ))
(setf (get 'assert-raise 'ed::lisp-indent-hook) 'progn)



(block test-empty-hash
  (assert nil (json:json-decode "{}"))
  (assert nil (json:json-decode "{}" :strict nil))
  (assert nil (json:json-decode "{}" :strict nil :json-object :alist))
  (assert-hashtable (make-hash-table :test 'equal)
                    (json:json-decode "{}" :json-object :hash-table))
  (assert-hashtable (make-hash-table :test 'eq)
                    (json:json-decode "{}" :json-object :hash-table
                                    :hash-table-test 'eq)))

(block test-hash-table
  (let ((h (json:json-decode "{\"foo\":123}"
                           :json-object :hash-table)))
    (assert 123 (gethash "foo" h))
    (assert nil (gethash "FOO" h)))
  (let ((h (json:json-decode "{\"foo\":123}"
                           :json-object :hash-table
                           :hash-table-test #'equalp)))
    (assert 123 (gethash "FOO" h))
    (assert 123 (gethash "FOO" h)))

  (let ((h (make-hash-table :test 'equal)))
    (setf (gethash "foo" h) 2)
    (assert-hashtable h (json:json-decode "{\"foo\":2,\"foo\":1}" :json-object :hash-table)))
  (assert 2 (cdr (assoc "foo" (json:json-decode "{\"foo\":2,\"foo\":1}")
                        :test #'equal))))

(block test-strict
  (assert '(("foo" . "bare"))
          (json:json-decode "{foo:bare}" :strict nil))
  (assert '(("foo" . "bare"))
          (json:json-decode "{\"foo\":bare}" :strict nil))
  (assert '(("foo" . "bare"))
          (json:json-decode "{\"foo\":\"bare\"}" :strict nil))
  (assert '(("foo" . "bare"))
          (json:json-decode "  {  \"foo\"  :  \"bare\"  }  " :strict nil))
  (assert '(("foo" . 1) ("bar" . 2))
          (json:json-decode "{
\"foo\": 1,
\"bar\": 2,
}" :strict nil))
  (assert '(("foo" . "1") ("bar" . "2"))
          (json:json-decode "{\"foo\":\"1\",\"bar\":\"2\"}"))
  (assert '(("foo" . t) ("bar" . nil) ("baz" . nil))
          (json:json-decode "{\"foo\":true, \"bar\" : false ,\"baz\":false}" :strict nil)))

(block test-toplevel-strict
  (assert "foo" (json:json-decode "\"foo\"" :strict nil))
  (assert "foo" (json:json-decode "foo" :strict nil))
  (assert t (json:json-decode "true" :strict nil))
  (assert 123 (json:json-decode "123" :strict nil))

  (assert :jnull (json:json-decode "null)" :strict nil :json-null :jnull))
  (assert :jnull (json:json-decode "(null" :strict nil :json-null :jnull))
  (assert :jnull (json:json-decode "(null)" :strict nil :json-null :jnull))
  (assert :jtrue (json:json-decode "foo(true)" :strict nil :json-true :jtrue))
  (assert :jtrue (json:json-decode "foo(true" :strict nil :json-true :jtrue))
  (assert :jtrue (json:json-decode "true)" :strict nil :json-true :jtrue))

  (assert :jtrue (json:json-decode "Ten.JSONP(true)" :strict nil :json-true :jtrue))
  (assert :jtrue (json:json-decode "$F(true)" :strict nil :json-true :jtrue))
  (assert :jtrue (json:json-decode "$$(true)" :strict nil :json-true :jtrue))

  (assert '((1 . 2)) (json:json-decode "foo({1:2})" :strict nil))
  )

(assert nil (json:json-decode "[]"))
(assert nil (json:json-decode "[]" :array :list))
(assert-vector (make-vector 0)
               (json:json-decode "[]" :json-array :array))

(assert '(t nil nil)
        (json:json-decode "[true,false,null]"))
(assert '(:TRUE :FALSE :NULL)
        (json:json-decode "[true,false,null]"
                        :json-true :TRUE :json-false :FALSE :json-null :NULL))
(assert '(1 2 3) (json:json-decode "[1,2,3]"))
(assert '("1" "2" "3") (json:json-decode "[\"1\",\"2\",\"3\"]"))
(assert '(1 2 3) (json:json-decode "[1,2,3,]" :strict nil))

(assert '(("quote" . "外は-14.9度。") ("name" . "miyamuko"))
        (json:json-decode "{\"quote\":\"\\u5916\\u306f-14.9\\u5ea6\\u3002\",\"name\":\"miyamuko\"}"))
(assert
 '(("rks" . "abecec310de8fdc0c7c3c2d98329297bb22509d4")
   ("can_comment" . 1)
   ("entries" (("stars" (("quote" . "") ("name" . "boundary-line")))
               ("can_comment" . 1)
               ("comments")
               ("uri" . "http://h.hatena.ne.jp/miyamuko/9236539246803643147"))))
 (json:json-decode
  "{\"rks\":\"abecec310de8fdc0c7c3c2d98329297bb22509d4\",\"can_comment\":1,\"entries\":[{\"stars\":[{\"quote\":\"\",\"name\":\"boundary-line\"}],\"can_comment\":1,\"comments\":[],\"uri\":\"http://h.hatena.ne.jp/miyamuko/9236539246803643147\"}]}"))
(assert '(("title" . "はてなスター日記")
          ("uri" . "http://d.hatena.ne.jp/hatenastar/")
          ("star_count" . "75630"))
        (json:json-decode
         "{\"title\":\"\\u306f\\u3066\\u306a\\u30b9\\u30bf\\u30fc\\u65e5\\u8a18\",
\"uri\":\"http://d.hatena.ne.jp/hatenastar/\",
\"star_count\":\"75630\"}"))


(assert '(1 2 t)
        (json:json-decode "([1,2,true])" :strict nil))
(assert '(1 2 t)
        (json:json-decode "Ten.JSONP([1,2,true])" :strict nil))
(assert "1715"
        (cdr (assoc "count" (json:json-decode-file "test.json" :strict nil)
                    :test #'equal)))

(assert '("foo bar" "bar baz")
        (json:json-decode "[foo bar   ,bar baz   ,  ]" :strict nil))


(assert-raise json:json-argument-error
  (json:json-decode "{}" :strict nil :json-object t))
(assert-raise json:json-argument-error
  (json:json-decode "{}" :strict nil :json-object nil))
(assert-raise json:json-argument-error
  (json:json-decode "{}" :strict nil :json-object :list))

(assert-raise json:json-parse-error
  (json:json-decode "" :strict t))
(assert-raise json:json-parse-error
  (json:json-decode "[1,2,3,]" :strict t))
(assert-raise json:json-parse-error
  (json:json-decode "[  1  ,  2 , 3 , ]" :strict t))
(assert-raise json:json-parse-error
  (json:json-decode "[1,2,3,,]" :strict nil))

(assert-raise json:json-parse-error
  (json:json-decode "{"))
(assert-raise json:json-parse-error
  (json:json-decode "}"))
(assert-raise json:json-parse-error
  (json:json-decode "{:}"))
(assert-raise json:json-parse-error
  (json:json-decode "{foo:}"))
(assert-raise json:json-parse-error
  (json:json-decode "{\"foo\":}"))
(assert-raise json:json-parse-error
  (json:json-decode "{\"foo\":bare}"))
(assert-raise json:json-parse-error
  (json:json-decode "{\"foo\":\"bare\",}"))

(assert-raise type-error
  (json:json-decode nil))
(assert-raise type-error
  (json:json-decode-file nil))
(assert-raise simple-error
  (json:json-decode-file ""))
(assert-raise simple-error
  (json:json-decode-file "no such file"))

