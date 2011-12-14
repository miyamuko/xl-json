# xl-json - JSON パーサ

  * Home URL: <http://miyamuko.s56.xrea.com/xyzzy/json/intro.htm>
  * Version: 0.1.2


## SYNOPSIS

```lisp
(require "json")

(json:json-decode
 "{\"title\":\"\\u306f\\u3066\\u306a\\u30b9\\u30bf\\u30fc\\u65e5\\u8a18\",
   \"uri\":\"http://d.hatena.ne.jp/hatenastar/\",
   \"star_count\":\"75630\"}")
;;=> (("title" . "はてなスター日記")
;;    ("uri" . "http://d.hatena.ne.jp/hatenastar/")
;;    ("star_count" . "75630"))

(require "xml-http-request")
(json:json-decode
 (xhr:xhr-get (concat "http://api.awasete.com/showjson.phtml?u="
                  (si:www-url-encode "http://blog.myrss.jp/"))
          :key 'xhr:xhr-response-text)
 :strict nil)
;;=> ((("title" . "CSS HappyLife")
;;     ("url" . "http://css-happylife.com/")
;;     ("favicon" . "http://faviapi.sidetools.com/?url=http%3A%2F%2Fcss-happylife.com%2F&c=4c8a5890")
;;     ("navigation" . "http://awasete.com/bar.phtml?u=http%3A%2F%2Fcss-happylife.com%2F&p=http%3A%2F%2Fblog.myrss.jp%2F")
;;     ("more" . "http://awasete.com/show.phtml?u=http%3A%2F%2Fcss-happylife.com%2F"))
;;    (("title" . "モチベーションは楽しさ創造から")
;;     ("url" . "http://d.hatena.ne.jp/favre21/")
;;     ("favicon" . "http://faviapi.sidetools.com/?url=http%3A%2F%2Fd.hatena.ne.jp%2Ffavre21%2F&c=e1c17aea")
;;     ("navigation" . "http://awasete.com/bar.phtml?u=http%3A%2F%2Fd.hatena.ne.jp%2Ffavre21%2F&p=http%3A%2F%2Fblog.myrss.jp%2F")
;;     ("more" . "http://awasete.com/show.phtml?u=http%3A%2F%2Fd.hatena.ne.jp%2Ffavre21%2F"))
;;    ;; 省略
;;    )
```

## DESCRIPTION

xl-json は xyzzy Lisp のみで実装した JSON パーサです。

## INSTALL

  1. [NetInstaller](http://www7a.biglobe.ne.jp/~hat/xyzzy/ni.html)
     で json をインストールします。
  
  2. xl-json はライブラリであるため自動的にロードはされません。
     必要な時点で require してください。


## MODULE

### DEPENDS

依存ライブラリはありません。


### PACKAGE

json は以下のパッケージを利用しています。

  * json


### VARIABLE

なし。


### CONSTANT

なし。


### CODITION

#### <a name="json-simple-error"> json:json-simple-error

[json-parse-error](#json-parse-error),
[json-argument-error](#json-argument-error)
の親コンディションです。

このコンディション自体が通知されることはありません。

#### <a name="json-parse-error"> json:json-parse-error

不正な json text を指定した場合に通知される例外です。

#### <a name="json-argument-error"> json:json-argument-error

[json-decode](#json-decode) に不正な引数を指定した場合に通知される例外です。


### COMMAND

なし。


### FUNCTION

#### <a name="json-decode"> json:json-decode JSON-TEXT &REST OPTIONS

JSON テキストを読み込み S 式に変換します。
`JSON-TEXT` には JSON を文字列で指定します。
文字列以外を指定した場合は type-error 例外を通知します。

`OPTIONS` には以下のキーワードを指定可能です。

  * `:strict`

    厳密に JSON をパースするかどうか指定します。
    デフォルトは t です。

    * `:strict` が non-nil なら RFC に準拠して厳密にパースします。
    * `:strict` が nil なら以下のような RFC に準拠していない JSON も受け付けます。

      ```lisp
      ;; クォートされていない文字列
      (json-decode "{lang:lisp}" :strict t)
      ;;=> json parse error: bare word not allowed.
      (json-decode "{lang:lisp}" :strict nil)
      ;;=> (("lang" . "lisp"))

      ;; シングルクォートで囲まれた文字列
      (json-decode "{'lang':'lisp'}" :strict t)
      ;;=> json parse error: single quoted string not allowed.
      (json-decode "{'lang':'lisp'}" :strict nil)
      ;;=> (("lang" . "lisp"))

      ;; Objects, Arrays の最後に余計なカンマ
      (json-decode "{\"lang\":[\"lisp\",\"ruby\",],}" :strict t)
      ;;=> json parse error: unexpected ']', expecting json value.
      (json-decode "{\"lang\":[\"lisp\",\"ruby\",],}" :strict nil)
      ;;=> (("lang" "lisp" "ruby"))

      ;; トップレベルの Objects, Arrays の周辺にゴミがある
      (json-decode "JSONP({\"lang\":\"lisp\"})" :strict t)
      ;;=> json parse error: bare word not allowed.
      (json-decode "JSONP({\"lang\":\"lisp\"})" :strict nil)
      ;;=> (("lang" . "lisp"))

      ;; トップレベルが Objects, Arrays 以外でも受け付ける
      (json-decode "true" :strict t)
      ;;=> json parse error: unexpected bare word, expecting object or array.
      (json-decode "true" :strict nil)
      ;;=> t
      (json-decode "\"hoge\"" :strict t)
      ;;=> json parse error: unexpected string, expecting object or array.
      (json-decode "\"hoge\"" :strict nil)
      ;;=> "hoge"
      ```

  * `:json-null`

    JSON の null に対応する lisp の値を指定します。

    デフォルト値は nil です。

    ```lisp
    (json-decode "{\"name\": null}" :json-null :NULL)
    ;; => (("name" . :NULL))
    ```

  * `:json-true`

    JSON の true に対応する lisp の値を指定します。

    デフォルト値は t です。

    ```lisp
    (json-decode "{\"xyzzy\": true}" :json-true :TRUE)
    ;; => (("xyzzy" . :TRUE))
    ```

  * `:json-false`

    JSON の false に対応する lisp の値を指定します。

    デフォルト値は nil です。

    ```lisp
    (json-decode "{\"xyzzy\": false}" :json-false :FALSE)
    ;; => (("xyzzy" . :FALSE))
    ```

  * `:json-array`

    JSON の Arrays のマッピング方法を指定します。

    * 引数は `:list` または `:array` を指定します。
    * `:list` を指定した場合はリストにマッピングします。
    * `:array` を指定した場合は配列にマッピングします。

    デフォルト値は `:list` です。

    ```lisp
    (json-decode "[1, 2, 3]" :json-array :list)
    ;; => (1 2 3)

    (json-decode "[1, 2, 3]" :json-array :array)
    ;; => #(1 2 3)
    ```

  * `:json-object`

    JSON の Objects のマッピング方法を指定します。

    * 引数は `:alist` または `:hash-table` を指定します。
    * `:alist` を指定した場合は関連リストにマッピングします。
    * `:hash-table` を指定した場合は hashtable にマッピングします。

    デフォルト値は `:alist` です。

    ```lisp
    (json-decode "{\"xyzzy\": \"common lisp\", \"emacs\": \"emacs lisp\"}" :json-object :alist)
    ;; => (("xyzzy" . "common lisp") ("emacs" . "emacs lisp"))

    (setf h (json-decode "{\"xyzzy\": \"common lisp\", \"emacs\": \"emacs lisp\"}" :json-object :hash-table))
    ;; => #<hashtable 52893588>
    (gethash "xyzzy" h)
    ;; => "common lisp"
    ;;    t
    (gethash "emacs" h)
    ;; => "emacs lisp"
    ;;    t
    ```

    `:hash-table-test` も参照してください。

  * `:hash-table-test`

    hash-table のテスト関数を指定します。

    * `json-object` に `:hash-table` を指定したときのみ有効なオプションです。
    * 指定可能な関数は `eq`, `eql`, `equal`, `equalp` です。

    デフォルトは `equal` です。

    ```lisp
    (setf h (json-decode "{\"name\": \"hogehoge\"}" :json-object :hash-table))
    ;; => #<hashtable 52893564>
    (hash-table-test h)
    ;; => equal
    (gethash "name" h)
    ;; => "hogehoge"
    ;;    t
    (gethash "NaME" h)
    ;; => nil
          nil

    (setf h (json-decode "{\"name\": \"hogehoge\"}" :json-object :hash-table :hash-table-test #'equalp))
    ;; => #<hashtable 52893180>
    (hash-table-test h)
    ;; => equalp
    (gethash "name" h)
    ;; => "hogehoge"
    ;;    t
    (gethash "NaME" h)
    ;; => "hogehoge"
    ;;    t
    ```

#### <a name="json-decode-file"> json:json-decode-file FILENAME &REST OPTIONS

`FILENAME` で指定されたファイルから JSON をロードします。

`OPTIONS` の指定方法は [json-decode](#json-decode) を参照してください。

#### <a name="json-version"> json:json-version

本ライブラリのバージョンを返します。
バージョンは major.minor.teeny という形式です。

それぞれの番号は必ず 1 桁にするので、以下のように比較することができます。

```lisp
(if (string<= "1.1.0" (json:json-version))
    '(1.1.0 以降で有効な処理)
  '(1.1.0 より前のバージョンでの処理))
```


### MACRO

なし。


## TODO

  * エラーメッセージに行数・カラム数を表示
  * strict を細かく指定
    * single-quote-allowed
    * bare-word-allowed
    * extra-comma-allowed
    * padding-allowed (junk-allowed)
  * emitter
  * json path
  * json-decode-from-stream
  * さらに高速化


## KNOWN BUGS

  * 巨大な数値は扱えません。

    ```lisp
    (json:json-decode "[23456789012E666]")
    ;;=> json parse error: invalid number: "23456789012E666" (オーバーフローしました)
    ```


## AUTHOR

みやむこ かつゆき (<mailto:miyamuko@gmail.com>)


## SEE ALSO

  * [JSON の紹介](http://www.json.org/json-ja.html)
  * [RFC 4627 The application/json Media Type for JavaScript Object Notation (JSON)](http://tools.ietf.org/html/rfc4627)
  * [Introducing json.el](http://emacsen.org/2006/03/26-json)
  * [CL-JSON A JSON parser and generator in Common-Lisp](http://common-lisp.net/project/cl-json/)


## COPYRIGHT

json は MIT/X ライセンスに基づいて利用可能です。

    Copyright (c) 2008,2010-2011 MIYAMUKO Katsuyuki.

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
