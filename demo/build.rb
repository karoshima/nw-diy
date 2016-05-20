#!/usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
################################################################
#
# ip netns を使って NW-DIY デモ環境を作成する
#
################################################################
# 以下のような環境を作り、screen コマンドで各ホストの bash を起動する
# 
#              +-------+
#              | north |
#              +---+---+
#                  |
#  +------+    +---+----+    +------+
#  | east +----+ center +----+ west |
#  +------+    +---+----+    +------+
#                  |
#              +---+---+
#              | south |
#              +-------+
#
# 各ホストには、対向する各装置に繋ぐインターフェースとして
# "<対向装置名>0" というインターフェースを用意している。
# 
# ちなみに、図には書いていないがフルメッシュにしている。
# そこまで使わないかもしれないけど、気が向いたら使える。
# 
# 各ホストは実際には VM でもコンテナでもなく、
# ip netns で作成した Network namespace 上で bash を起動して
# プロンプトをそれらしく見せているだけ。
################################################################
# screen を終わらせても、Network namespace たちは生きています。
# screen -c <このディレクトリ>/.screen することで
# 再び各ホストの操作が可能になります
#
# 使い終わった Network namespace たちは
# sh destroy.sh により掃除しましょう。
################################################################

hosts = %w(center east west north south)

# Network namespace を作る
hosts.each do |h|
  system "sudo ip netns add #{h}"
end

# できたばかりの ns では lo が linkdown してるので linkup させる
hosts.each do |h|
  system "sudo ip netns exec #{h} ip link set lo up"
end

# ns 間を veth で結ぶ
hosts.combination(2) do |pair|
  system "sudo ip link add name veth0 type veth peer name veth1" or
    raise "Cannot exec \"ip link add\", #{$?}"
  system "sudo ip link set veth0 netns #{pair[0]} name #{pair[1]}0"
  system "sudo ip link set veth1 netns #{pair[1]} name #{pair[0]}0"
  system "sudo ip netns exec #{pair[0]} ip link set #{pair[1]}0 up"
  system "sudo ip netns exec #{pair[1]} ip link set #{pair[0]}0 up"
end

# いろいろ操作してもらう
#system "screen -c #{File.dirname $0}/.screenrc"
# screen の準備
File.open(__dir__+"/.screen", "w") do |rc|
  rc.print <<'ENDOFSCREENRC'
# 操作性のため
source ~/.screenrc

# 画面の 9 分割とシェルの割り当て
split	      # 南北3分割
split	      # 南北3分割
split -v      # 北の東西3分割
split -v      # 北の東西3分割
focus down
split -v      # 中の東西3分割
split -v      # 中の東西3分割
focus down
split -v      # 南の東西3分割
split -v      # 南の東西3分割

# console 0
screen

# console 1 南西
screen
stuff "clear\n"

# console 2 南
focus next
screen -t south
stuff "exec sudo ip netns exec south bash\n"
stuff "export PS1='south# '\n"
stuff "ip addr add 10.0.0.2/24 dev center0\n"
stuff "export PATH=$PATH\n"
stuff "clear\n"

# console 3 南東
focus next
screen
stuff "clear\n"

# console 4 西
focus prev
focus prev
focus up
screen -t west
stuff "exec sudo ip netns exec west bash\n"
stuff "export PS1='west# '\n"
stuff "ip addr add 10.0.0.4/24 dev center0\n"
stuff "export PATH=$PATH\n" # su するけど PATH は今のまま
stuff "clear\n"

# console 5 中央
focus next
screen -t center
stuff "exec sudo ip netns exec center bash\n"
stuff "export PS1='center# '\n"
stuff "export PATH=$PATH\n" # su するけど PATH は今のまま
stuff "clear\n"

# console 6 東
focus next
screen -t east
stuff "exec sudo ip netns exec east bash\n"
stuff "export PS1='east# '\n"
stuff "ip addr add 10.0.0.6/24 dev center0\n"
stuff "export PATH=$PATH\n" # su するけど PATH は今のまま
stuff "clear\n"

# console 7 北西
focus prev
focus prev
focus up
screen
stuff "clear\n"

# console 8 北
focus next
screen -t east
stuff "exec sudo ip netns exec north bash\n"
stuff "export PS1='north# '\n"
stuff "ip addr add 10.0.0.8/24 dev center0\n"
stuff "export PATH=$PATH\n" # su するけど PATH は今のまま
stuff "clear\n"

# console 9 北東
focus next
screen
stuff "clear\n"

ENDOFSCREENRC
end
system "screen  -c #{__dir__}/.screen"
