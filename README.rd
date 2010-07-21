= json - 安全で高速な JSON パーサ

  * Author: みやむこ かつゆき ((<URL:mailto:miyamuko@gmail.com>))
  * Home URL: ((<URL:http://miyamuko.s56.xrea.com/xyzzy/json/intro.htm>))
  * Version: 0.1.2


== SYNOPSIS

  (require "json")
  (use-package :json)

  (json-decode
   "{\"title\":\"\\u306f\\u3066\\u306a\\u30b9\\u30bf\\u30fc\\u65e5\\u8a18\",
     \"uri\":\"http://d.hatena.ne.jp/hatenastar/\",
     \"star_count\":\"75630\"}")
  ;;=> (("title" . "はてなスター日記")
  ;;    ("uri" . "http://d.hatena.ne.jp/hatenastar/")
  ;;    ("star_count" . "75630"))

  (json-decode
   (xhr-get (concat "http://api.awasete.com/showjson.phtml?u="
                    (si:www-url-encode "http://blog.myrss.jp/"))
            :key 'xhr-response-text)
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


== DESCRIPTION

json は xyzzy Lisp のみで実装した JSON パーサです。
json-syck より高速でかつ外部ライブラリを利用していないので安全（クラッシュすることがない）です。

json はライブラリです。
アプリケーションは以下のコードを追加することで json を利用することができます。

  (in-package :you-awesome-app)
  (require "json")
  (use-package :json)

  (your beautiful code)


== INSTALL

=== NetInstaller でインストール

(1) ((<NetInstaller|URL:http://www7a.biglobe.ne.jp/~hat/xyzzy/ni.html>))
    で json をインストールします。

=== NetInstaller を使わずにインストール

(1) アーカイブをダウンロードします。

    ((<URL:http://miyamuko.s56.xrea.com/xyzzy/archives/json.zip>))

(2) アーカイブを展開して、$XYZZY/site-lisp 配下にファイルをコピーします。


== MODULE

=== DEPENDS

依存ライブラリはありません。


=== PACKAGE

json は以下のパッケージを利用しています。

  * json


=== VARIABLE

なし。


=== CONSTANT

なし。


=== CODITION

--- json:json-simple-error

    json-parse-error, json-argument-error の親コンディションです。

    このコンディション自体が通知されることはありません。

--- json:json-parse-error

    不正な json text を指定した場合に通知される例外です。

--- json:json-argument-error

    json-decode に不正な引数を指定した場合に通知される例外です。


=== COMMAND

なし。

=== FUNCTION

--- json:json-decode JSON-TEXT &REST OPTIONS

    JSON テキストを読み込み S 式に変換します。

    * JSON-TEXT には JSON を文字列で指定します。
    * 文字列以外を指定した場合は type-error 例外を通知します
    * 引数 OPTIONS はパーサオプションを指定します。
      パーサオプションは キーワードリストで指定します。

    以下のオプションを指定可能です。

    * ((< strict >))
    * ((< json-null >))
    * ((< json-true >))
    * ((< json-false >))
    * ((< json-array >))
    * ((< json-object >))
    * ((< hash-table-test >))

    : strict
        厳密に JSON をパースするかどうか指定します。

        * strict が non-nil なら RFC に準拠して厳密にパースします。
        * strict が nil なら以下のような RFC に準拠していない JSON も受け付けます。
          * クォートされていない文字列
              (json-decode "{lang:lisp}" :strict t)
              ;;=> json parse error: bare word not allowed.
              (json-decode "{lang:lisp}" :strict nil)
              ;;=> (("lang" . "lisp"))
          * シングルクォートで囲まれた文字列
              (json-decode "{'lang':'lisp'}" :strict t)
              ;;=> json parse error: single quoted string not allowed.
              (json-decode "{'lang':'lisp'}" :strict nil)
              ;;=> (("lang" . "lisp"))
          * Objects, Arrays の最後に余計なカンマ
              (json-decode "{\"lang\":[\"lisp\",\"ruby\",],}" :strict t)
              ;;=> json parse error: unexpected ']', expecting json value.
              (json-decode "{\"lang\":[\"lisp\",\"ruby\",],}" :strict nil)
              ;;=> (("lang" "lisp" "ruby"))
          * トップレベルの Objects, Arrays の周辺にゴミがある
              (json-decode "JSONP({\"lang\":\"lisp\"})" :strict t)
              ;;=> json parse error: bare word not allowed.
              (json-decode "JSONP({\"lang\":\"lisp\"})" :strict nil)
              ;;=> (("lang" . "lisp"))
          * トップレベルが Objects, Arrays 以外でも受け付ける
              (json-decode "true" :strict t)
              ;;=> json parse error: unexpected bare word, expecting object or array.
              (json-decode "true" :strict nil)
              ;;=> t
              (json-decode "\"hoge\"" :strict t)
              ;;=> json parse error: unexpected string, expecting object or array.
              (json-decode "\"hoge\"" :strict nil)
              ;;=> "hoge"

        デフォルトは t です。

    : json-null
        JSON の null に対応する lisp の値を指定します。

        デフォルト値は nil です。

          (json-decode "{\"name\": null}" :json-null :NULL)
          ;; => (("name" . :NULL))

    : json-true
        JSON の true に対応する lisp の値を指定します。

        デフォルト値は t です。

          (json-decode "{\"xyzzy\": true}" :json-true :TRUE)
          ;; => (("xyzzy" . :TRUE))

    : json-false
        JSON の false に対応する lisp の値を指定します。

        デフォルト値は nil です。

          (json-decode "{\"xyzzy\": false}" :json-false :FALSE)
          ;; => (("xyzzy" . :FALSE))

    : json-array
        JSON の Arrays のマッピング方法を指定します。

        * 引数は :list または :array を指定します。
        * :list を指定した場合はリストにマッピングします。
        * :array を指定した場合は配列にマッピングします。

        デフォルト値は :list です。

          (json-decode "[1, 2, 3]" :json-array :list)
          ;; => (1 2 3)

          (json-decode "[1, 2, 3]" :json-array :array)
          ;; => #(1 2 3)

    : json-object
        JSON の Objects のマッピング方法を指定します。

        * 引数は :alist または :hash-table を指定します。
        * :alist を指定した場合は関連リストにマッピングします。
        * :hash-table を指定した場合は hashtable にマッピングします。

        デフォルト値は :alist です。

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

        ((<hash-table-test>)) も参照してください。

    : hash-table-test
        hash-table のテスト関数を指定します。

        * ((<json-object>)) に :hash-table を指定したときのみ有効なオプションです。
        * 指定可能な関数は eq, eql, equal, equalp です。

        デフォルトは equal です。

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

--- json:json-decode-file FILENAME &REST OPTIONS

    指定されたファイルから JSON をロードします。

    OPTIONS の指定方法は
    ((<json-decode|json:json-decode JSON-TEXT &REST OPTIONS>))
    を参照してください。

--- json:json-version

    本ライブラリのバージョンを返します。
    バージョンは major.minor.teeny という形式です。

    それぞれの番号は必ず 1 桁にするので、以下のように比較することができます。

        (if (string<= "1.1.0" (json:json-version))
            '(1.1.0 以降で有効な処理)
          '(1.1.0 より前のバージョンでの処理))

=== MACRO

なし。


== TODO

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


== KNOWN BUGS

* 巨大な数値は扱えません。

    (json:json-decode "[23456789012E666]")
    ;;=> json parse error: invalid number: "23456789012E666" (オーバーフローしました)


== AUTHOR

みやむこ かつゆき (((<URL:mailto:miyamuko@gmail.com>)))


== SEE ALSO

  : JSON の紹介
      ((<URL:http://www.json.org/json-ja.html>))

  : RFC 4627 The application/json Media Type for JavaScript Object Notation (JSON)
      ((<URL:http://tools.ietf.org/html/rfc4627>))

  : Introducing json.el
      ((<URL:http://emacsen.org/2006/03/26-json>))

  : CL-JSON A JSON parser and generator in Common-Lisp.
      ((<URL:http://common-lisp.net/project/cl-json/>))


== COPYRIGHT

json は MIT/X ライセンスに基づいて利用可能です。

See json/docs/MIT-LICENSE for full license.


== NEWS

<<<NEWS.rd
