NW-DIY // demo

====

## ruby build.rb

デモ環境を整えます。

テキスト画面を 3x3 分割するので、事前に画面を大きくしてから実行してください。

## sh story.sh

デモを実行します。

## sh destroy.sh

GNU screen を terminate させるだけでは消えないリソースを掃除します。

デモ実行後、GNU screen を terminate させてからこのスクリプトをしてください。

## Detail

デモ作成にあたり、潤沢に PC やサーバーを持っているわけではないため、
Linux Network namespace で PC を分割して複数に見せています。

build.rb では環境構築のため、以下の作業を行なっています。

1. Linux Network namespace の作成
2. namespace 同士を仮想イーサネット (veth) で接続
3. 画面の 3x3 分割と初期化
4. デモに使う namespace への IPv4 アドレス付与

story.sh では以下のストーリーでデモを進めます。

1. リピータハブの動作確認
  1. 上側端末から下側端末に ping を打ち始める
  2. 中央端末 (右上エディタ画面) で NW-DIY でリピータライブラリを作成する
  3. 中央端末で対話シェル `irb` からリピータライブラリを読み込み、稼動させる
  4. 上下を繋ぎ込んだら ping が通ることを確認する。
2. リピータハブに学習機能をつける
  5. 中央端末 (右上エディタ画面) でリピータライブラリを改造する
  6. 中央端末で対話シェル `irb` からリピータライブラリを読み込み、稼動させる
  7. 上下だけに ping が通ることを確認する。

## Requirement

* Linux の Network namespace
* GNU screen
* sudo 権限 (自分のアカウントが NOPASSWD してあること、あるいは既に root であること)
* TeraTerm や gnome-terminal などのターミナルソフト
