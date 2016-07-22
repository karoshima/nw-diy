#!/bin/sh
################################################################
# Copyright (c) 2016 KASHIMA Hiroaki <kashima@jp.fujitsu.com>
# 本ツールは Apache License 2.0 ライセンスで公開します。
# 著作権については ./LICENSE もご確認ください

        screen -X -p 7 stuff "cat > /dev/null\n"
        screen -X -p 7 stuff "NW-DIY のデモを行ないます。\n"
sleep 1;screen -X -p 7 stuff "よろしくお願いします。\n"
sleep 2;screen -X -p 7 stuff "画面中央の装置でスイッチを動かして\n"
sleep 2;screen -X -p 7 stuff "上の装置から下の装置への ping を通します。\n"
sleep 2;screen -X -p 7 stuff "このスイッチに簡単な改造を加えるだけで\n"
sleep 2;screen -X -p 7 stuff "新しい機能が有効になる様子をご覧ください。\n"
sleep 2;screen -X -p 7 stuff "\nまず、デモ環境について解説します。\n"
sleep 2;screen -X -p 7 stuff "中央の装置は、周囲の東西南北の装置に対して\n"
sleep 2;screen -X -p 7 stuff "east0, west0, south0, north0 という\n"
sleep 2;screen -X -p 7 stuff "イーサネットで接続しています。\n"
sleep 2;screen -X -p 7 stuff "周囲の装置は、中央の装置に対して\n"
sleep 2;screen -X -p 7 stuff "center0 というイーサネットで接続しています。\n"
sleep 3;screen -X -p 7 stuff "\nそれではデモを行ないます。\n"
sleep 2;screen -X -p 7 stuff "\nまず、なにも動いていない環境で、\n"
sleep 2;screen -X -p 7 stuff "north から south に ping を打ちます。\n"
sleep 1;screen -X -p 8 stuff "ping 10.0.0.2\n"
sleep 3;screen -X -p 7 stuff "他の機器では tcpdump を仕掛けておきます。\n"
sleep 1;screen -X -p 2 stuff "tcpdump -ni center0\n"
sleep 1;screen -X -p 4 stuff "tcpdump -ni center0\n"
sleep 1;screen -X -p 6 stuff "tcpdump -ni center0\n"
sleep 3;screen -X -p 7 stuff "center がいるので届きませんね。\n"
sleep 2;screen -X -p 7 stuff "それでは center でスイッチを動かします。\n"
sleep 2;screen -X -p 7 stuff "そのためのスイッチを作りましょう。\n"
sleep 3;screen -X -p 9 stuff "rm switch.rb; vi switch.rb\n"
sleep 1;screen -X -p 9 stuff "i"
sleep 1;screen -X -p 9 stuff "require_relative '../lib/nwdiy'\n"
sleep 1;screen -X -p 9 stuff "require 'nwdiy/vm'\n"
sleep 1;screen -X -p 9 stuff "\n"
sleep 1;screen -X -p 9 stuff "class Switch < NwDiy::VM\n"
sleep 3;screen -X -p 7 stuff "Switch クラスでスイッチを作ります\n"
sleep 3;screen -X -p 9 stuff "  def job\n"
sleep 1;screen -X -p 9 stuff "    loop do\n"
sleep 3;screen -X -p 7 stuff "job というメソッドでループをまわします。\n"
sleep 3;screen -X -p 9 stuff "      rifp, pkt = self.recv     # 受信したら\n"
sleep 1;screen -X -p 9 stuff "      self.iflist.each do |ifp| # 各ifpのうち\n"
sleep 1;screen -X -p 9 stuff "        (ifp == rifp) or        # 受信ifp以外に\n"
sleep 1;screen -X -p 9 stuff "          ifp.send(pkt)         # 送信する\n"
sleep 1;screen -X -p 9 stuff "      end\n"
sleep 2;screen -X -p 7 stuff "パケットを受信したら、\n"
sleep 2;screen -X -p 7 stuff "受信インターフェース以外に\n"
sleep 2;screen -X -p 7 stuff "転送します\n"
sleep 1;screen -X -p 9 stuff "    end\n  end\nend"
sleep 1;screen -X -p 9 stuff ":w\n"
sleep 2;screen -X -p 7 stuff "ではこれを center で動かしましょう。\n"
sleep 2;screen -X -p 7 stuff "NW-DIY は ruby で書かれていますので、\n"
sleep 2;screen -X -p 7 stuff "シェルから ruby を扱う irb コマンドを使います。\n"
sleep 2;screen -X -p 5 stuff "irb\n"
sleep 1;screen -X -p 5 stuff "require_relative 'switch.rb'\n"
sleep 1;screen -X -p 5 stuff "sw = Switch.new('north0')\n"
sleep 2;screen -X -p 7 stuff "Switch を作りました。\n"
sleep 2;screen -X -p 7 stuff "north0 インターフェースに繋がってます。\n"
sleep 2;screen -X -p 7 stuff "それではこの Switch を動かします。\n"
sleep 1;screen -X -p 5 stuff "\n"
sleep 1;screen -X -p 5 stuff "Thread.new { sw.job }\n"
sleep 2;screen -X -p 7 stuff "別スレッドでSwitch の job を動かしました。\n"
sleep 2;screen -X -p 7 stuff "右上画面のコードが裏で動いています。\n"
sleep 2;screen -X -p 7 stuff "\nここで、east と west を繋ぎ込みます。\n"
sleep 2;screen -X -p 5 stuff "sw.addif(['east0', 'west0'])\n"
sleep 3;screen -X -p 7 stuff "east や west に ARP が届くようになりました。\n"
sleep 2;screen -X -p 7 stuff "しかしまだ 'south0' を加えてないので、\n"
sleep 1;screen -X -p 7 stuff "south には届いていません。\n"
sleep 2;screen -X -p 7 stuff "south も繋ぎ込みましょう。\n"
sleep 1;screen -X -p 5 stuff "\n"
sleep 1;screen -X -p 5 stuff "sw.addif('south0')\n"
sleep 3;screen -X -p 7 stuff "south を繋ぐと ping 応答が得られます。\n"
sleep 1;screen -X -p 7 stuff "これでひとまず完成です。\n"
sleep 1;screen -X -p 7 stuff "..."
sleep 1;screen -X -p 7 stuff "..."
sleep 1;screen -X -p 7 stuff "..."
sleep 1;screen -X -p 7 stuff "\nまるで昔のリピータのように\n"
sleep 1;screen -X -p 7 stuff "余計なパケットが東西に漏れていますね。\n"
sleep 1;screen -X -p 7 stuff "イマドキのスイッチはこれを漏らさないよう\n"
sleep 1;screen -X -p 7 stuff "学習テーブルの機能があります。\n"
sleep 3;screen -X -p 7 stuff "\nそれではこれから\n"
sleep 1;screen -X -p 7 stuff "その学習テーブルの機能を拡張しましょう。\n"
sleep 2;screen -X -p 7 stuff "その前にちょっと、\n"
sleep 1;screen -X -p 7 stuff "このスイッチは止めておきましょう\n"
sleep 1;screen -X -p 5 stuff ""
sleep 1;screen -X -p 5 stuff "\n"
sleep 2;screen -X -p 7 stuff "center のスイッチを止めました\n"
sleep 2;screen -X -p 7 stuff "tcpdump の画面もずらしておきます\n"
sleep 1;screen -X -p 2 stuff "\n\n\n"
sleep 1;screen -X -p 4 stuff "\n\n\n"
sleep 1;screen -X -p 6 stuff "\n\n\n"
sleep 2;screen -X -p 7 stuff "それではコードを改造します。\n"
sleep 2;screen -X -p 7 stuff "装置ができるときに学習テーブルを用意します。\n"
sleep 1;screen -X -p 9 stuff "1Gjorequire 'nwdiy/timerhash'"
sleep 1;screen -X -p 9 stuff "jjo\n"
sleep 1;screen -X -p 9 stuff "  def initialize(*arg)\n"
sleep 1;screen -X -p 9 stuff "    super(*arg)\n"
sleep 2;screen -X -p 7 stuff "インスタンス生成時に\n"
sleep 2;screen -X -p 7 stuff "学習テーブルを作ります\n"
sleep 1;screen -X -p 9 stuff "    @macdb = NwDiy::TimerHash.new\n"
sleep 1;screen -X -p 9 stuff "    @macdb.age = 10\n"
sleep 1;screen -X -p 7 stuff "学習したデータは 10 秒で ageout させましょう。\n"
sleep 2;screen -X -p 9 stuff "  end\n"
sleep 2;screen -X -p 7 stuff "次にパケット送受信部を改造します。\n"
sleep 2;screen -X -p 9 stuff "jjjo\n"
sleep 2;screen -X -p 7 stuff "パケットを受信したらまず\n"
sleep 2;screen -X -p 7 stuff "送信元 MAC をキーに\n"
sleep 2;screen -X -p 7 stuff "受信インターフェースを登録します\n"
sleep 2;screen -X -p 9 stuff "      # 受信インターフェース登録\n"
sleep 1;screen -X -p 9 stuff "      @macdb.overwrite(pkt.src, rifp)\n"
sleep 2;screen -X -p 7 stuff "今度は送信先 MAC をキーに\n"
sleep 2;screen -X -p 7 stuff "送信インターフェースを検索します。\n"
sleep 2;screen -X -p 7 stuff "見つかったら、そこだけに転送します\n"
sleep 2;screen -X -p 9 stuff "      # 送信インターフェース確認\n"
sleep 1;screen -X -p 9 stuff "      sifp = @macdb.value(pkt.dst)\n"
sleep 1;screen -X -p 9 stuff "      if sifp\n"
sleep 1;screen -X -p 9 stuff "        sifp.send(pkt)\n"
sleep 1;screen -X -p 9 stuff "        next\n"
sleep 1;screen -X -p 9 stuff "      end\n"
sleep 1;screen -X -p 9 stuff "j"
sleep 1;screen -X -p 9 stuff "j"
sleep 1;screen -X -p 9 stuff "j"
sleep 1;screen -X -p 9 stuff "j"
sleep 1;screen -X -p 9 stuff "j:w\n"
sleep 3;screen -X -p 7 stuff "これで学習テーブルが効くようになったハズです。\n"
sleep 2;screen -X -p 7 stuff "ではこれを動かしてみましょう。\n"
sleep 2;screen -X -p 5 stuff "irb\n"
sleep 1;screen -X -p 5 stuff "require_relative 'switch'\n"
sleep 1;screen -X -p 5 stuff "sw = Switch.new('north0')\n"
sleep 1;screen -X -p 5 stuff "Thread.new { sw.job }\n"
sleep 2;screen -X -p 7 stuff "先ほどと同様に Switch を作って\n"
sleep 2;screen -X -p 7 stuff "動かし始めました。\n"
sleep 2;screen -X -p 7 stuff "ここに east と west を繋ぎ込みます。\n"
sleep 2;screen -X -p 5 stuff "\n"
sleep 1;screen -X -p 5 stuff "sw.addif(['east0', 'west0'])\n"
sleep 3;screen -X -p 7 stuff "east や west に ARP が届くようになりました。\n"
sleep 2;screen -X -p 7 stuff "まだ south を繋いでいないので、\n"
sleep 1;screen -X -p 7 stuff "さっきと挙動が同じです。\n"
sleep 3;screen -X -p 7 stuff "では south を繋ぎ込みましょう。\n"
sleep 1;screen -X -p 5 stuff "\n"
sleep 1;screen -X -p 5 stuff "sw.addif('south0')\n"
sleep 3;screen -X -p 7 stuff "south を繋ぐと ping 応答が得られます。\n"
sleep 1;screen -X -p 7 stuff "そして east や west のパケットが止まりました。\n"
sleep 1;screen -X -p 7 stuff "これで学習の機能も完成です。\n"
sleep 10;screen -X -p 7 stuff "\n10 秒ごとに 1 発づつ東西に出てきています。\n"
sleep 1;screen -X -p 7 stuff "学習テーブルが 10 秒ごとに  ageout している\n"
sleep 1;screen -X -p 7 stuff "様子が見てとれます。\n"
sleep 3;screen -X -p 7 stuff "\n【まとめ】\n"
sleep 1;screen -X -p 7 stuff "このように、ハードやカーネルを改造しなくても\n"
sleep 1;screen -X -p 7 stuff "既存の機能を拡張することが容易です。\n"
sleep 1;screen -X -p 7 stuff "\n"
