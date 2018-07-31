# ruby 版 NW-DIY のトップモジュール

いろんなネットワーク機能をモデル化することで、
レイヤごとの処理を明快に定義することができるようになります。

## モジュール構成

ネットワーク機能を大別すると、パケットそのものの振舞いを定義した
パケットモジュールと、パケットの扱いを定義した機能モジュールの
二種類に分けることができます。

### Nwdiy::Packet

パケットそのものの構成や振舞いを定義したパケットモジュールです。
バイナリデータとの相互変換や、データの梱包あるいは梱包したデータの
取り出し、文字列表現やコネクション情報などがあります。

### Nwdiy::Func

パケットの特定のレイヤ (パケット種別) を処理する機能モジュールです。

たとえばイーサネットインターフェースや L2 スイッチは、
イーサネットフレームである Nwdiy::Packet::Ethernet を処理するので、
Nwdiy::Func::Ethernet の機能を含んでいます。
たとえば IP インターフェースやルータ, NAT などは、
IP パケットである Nwdiy::Packet::IPv4 を処理するので、
Nwdiy::Func::IPv4 の機能を含んでいます。

この機能モジュールをインクルードしたクラスのインスタンスは、
パケットのフィールド名とその値あるいは別名を指定することで
梱包されたデータの中身を処理するクラスを設定できます。
たとえばイーサネットインターフェースであるインスタンス eth0 にとって
eth0.ipv4 は IPv4 フレームを扱うインスタンスですし、
eth0.vlan(16).ipv6 は VLAN id 16 上で IPv6 を扱うインスタンスです。
下記の例では、階層として示しています。

この機能モジュールを持つインスタンスは、パイプで繋ぐことができます。
下記の例で、ハイフン (--) で示しています。

## 例

eth2 のセグメントを、EtherIP を使って、eth1 の先のXXXと繋ぐ。

```
  +----------+    +------+
  | etherip  | -- | eth2 |
  +----------+    +------+
  |   ipv4   |    |  OS  |
  +----------+    +------+
  |   eth1   |
  +----------+
  |    OS    |
  +----------+
```

```ruby
  irb> Nwdiy::OS.ethernet("eth1").ipv4(local: "192.0.2.1/24").etherip(peer: "192.0.2.2") | Nwdiy::OS.ethernet("eth2")
```

- 例

EtherIP にファイアウォールと QoS を導入して、eth2 を守る。

```
                         +----------+    +-----+    +------+    +------+
                         | etherip  | -- | fwB | -- | qosB | -- | eth2 |
                         +----------+    +-----+    +------+    +------+
                         |   ipv4   |                           |  OS  |
  +------+    +-----+    +----------+                           +------+
  | eth1 | -- | fwA | -- |   ethA   |
  +------+    +-----+    +----------+
  |  OS  |
  +------+
```

```ruby
  irb> fwA = Nwdiy::Func::Firewall.new(some settings)
  irb> fwB = Nwdiy::Func::Firewall.new(some settings)
  irb> qosB = Nwdiy::Func::QOS.new(some settings)
  irb> ethA = Nwdiy::Func::Ethernet.new("ethA")
  irb> Nwdiy::OS.ethernet("eth1") | fwA | ethA
  irb> ethA.ipv4(local: "192.0.2.1/24").etherip(peer: "192.0.2.2") | fwB | qosB | Nwdiy::OS.ethernet("eth2")
```

- 例

スイッチを介して DNS を引き、HTTP でデータを取得する。
いちおう外部からもアクセス可能。

```
  +--------+ +--------+                               +-------+ +-----+
  | brwser | | resolv |                               | httpd | | dns |
  +--------+ +--------+                               +-------+ +-----+
  |  tcp   | |  udp   |                               |  tcp  | | udp |
  +--------+-+--------+    +---------------------+    +-------+-+-----+
  |       ipv4A       |    |       bridge        |    |     ipv4B     |
  +-------------------+    +-----+-+-----+-+-----+    +---------------+
  |        ethA       | -- | eth | | eth | | eth | -- |      ethB     |
  +-------------------+    +-----+ +-----+ +-----+    +---------------+
                                   | OS  |
                                   +-----+
```

```ruby
  irb> ethA = Nwdiy::Func::Ethernet.new("ethA")
  irb> ethB = Nwdiy::Func::Ethernet.new("ethB")
  irb> bridge = Nwdiy::Func::Bridge.new
  irb> ethA | bridge.eth[0]
  irb> bridge.eth[1] = Nwdiy::OS.ethernet("eth0")
  irb> bridge.eth[2] | ethB
  irb> brwser = Nwdiy::Func::Browser.new
  irb> httpd = Nwdiy::Func::Httpd.new
  irb> resolv = Nwdiy::Func::Resolver.new
  irb> dns = Nwdiy::Func::DNS.new
  irb> ethA.ip[0] = "192.0.2.1/24"
  irb> ethA.ip[0].tcp.bind(brwser)
  irb> ethA.ip[0].udp.bind(resolv)
  irb> ethB.ip[0] = "198.58.100.1/24"
  irb> ethB.ip[0].tcp.bind(httpd, 80)
  irb> ethB.ip[0].udp.bind(dns, 53)
```

- 例

ルータを介して DNS を引き、HTTP でデータを取得する。
IPv4 インスタンスをパイプで繋いだりイーサネットインスタンスを
パイプで繋いだり、左右で違いがあるのは、ただ単純にどっちでもできる
という例示のためであり、この構成への必然性はありません。

```
  +--------+ +--------+            +--------+            +-------+ +-----+
  | brwser | | resolv |            | ospfv2 |            |  http | | dns |
  +--------+ +--------+    +-------+--------+-------+    +-------+ +-----+
  |  tcp   | |   udp  |    |         router         |    |  tcp  | | udp |
  +--------+-+--------+    +------+-+------+-+------+    +-------+-+-----+
  |       ipv4A       | -- | ipv4 | | ipv4 | | ipv4 | -- |     ipv4B     |
  +-------------------+    +------+ +------+ +------+    +---------------+
                                    | eth1 |
                                    +------+
                                    |  OS  |
                                    +------+
```

```ruby
  irb> ipv4A = Nwdiy::Func::IPv4.new("192.0.2.2/24")
  irb> ipv4B = Nwdiy::Func::IPv4.new("203.0.113.2/24")
  irb> router = Nwdiy::Func::Router.new
  irb> router.ip[0] = "192.0.2.1/24"
  irb> router.ip[1] = "198.51.100.1/24"
  irb> router.ip[2] = "203.0.113.1/24"
  irb> ipv4A | router.ip[0]
  irb> router.ip[1] = Nwdiy::OS.ethernet("eth1").ipv4(local: "198.51.100.2/24")
  irb> router.ip[2] | ipv4B
  irb> router.ospf.routerId = "192.0.2.1"
  irb> brwser = Nwdiy::Func::Browser.new
  irb> httpd = Nwdiy::Func::Httpd.new
  irb> resolv = Nwdiy::Func::Resolver.new
  irb> dns = Nwdiy::Func::DNS.new
  irb> ipv4A.tcp.bind(brwser)
  irb> ipv4B.tcp.bind(httpd, 80)
  irb> ipv4A.udp.bind(resolv)
  irb> ipv4B.udp.bind(dns, 53)
```

- 例

送信元 NAT を挟んで、おうちの外にアクセスする。

```
            +---------------+
            |     router    |
            +------+-+------+
            | ipv4 | | snat |
            +------+ +------+
            | eth1 | | eth2 |
            +------+ +------+
  ホーム -- |  OS  | |  OS  | -- 外部
  ネット    +------+ +------+    インターネット
```

```ruby
  irb> router = Nwdiy::Func::Router.new
  irb> snat = Nwdiy::Func::Snat.new
  irb> snat.xxx = xxx (いろいろ設定)
  irb> OS.ethernet("eth1").ipv4 = router.ip[0] = "192.0.2.1/24"
  irb> OS.ethernet("eth2").ipv4 = router.ip[1] = snat
```

- 例

宛先 NAT を挟んで、DMZ のサーバーにアクセスさせる。

```
            +---------------+
            |     router    |
            +------+-+------+
            | dnat | | ipv4 |
            +------+ +------+
            | eth1 | | eth2 |
            +------+ +------+
  外部   -- |  OS  | |  OS  | -- サーバーゾーン
  ネット    +------+ +------+
```

```ruby
  irb> router = Nwdiy::Func::Router.new
  irb> dnat = Nwdiy::Func::Dnat.new
  irb> dnat.xxx = xxx (いろいろ設定)
  irb> OS.ethernet("eth1").ipv4 = router.ip[0] = dnat
  irb> OS.ethernet("eth2").ipv4 = router.ip[1] = "198.51.100.1/24"
```

- 用語
	- 上位・下位: OSI 階層に沿って上下を区別する。
	- 沿わないものは「左右」とする。
		- 左右を持つ機能はおのおので「左」と「右」の役割を定義する。

- OS
	- グローバル変数として、起動時から 1 個だけ存在する。生成/削除しない。
	- 上位に eth のインスタンスを持つ
		- 実在する eth インターフェースと PF_PACKET でパケットを交換する。
		- tun, tap, veth など生成する。

- eth
	- 概要
		- イーサネットフレームを扱う。
	- 上位層との接続
		- 上位層からの送信を受け付ける
			- 送信先 MAC と Ether Data (と非必須な送信元 MAC) を受け取る。
			- Ethernet ヘッダを付けて下位層に渡す。
			- 送信先 MAC が自分なら、下位層に渡さず折り返し受信する。
			- 送信先 MAC が BC/MC なら、下位層にも渡すし折り返しもする。
	- 下位層との接続
		- 接続対象
			- なし (生成初期などの一時的な状態。/dev/null 状態)
			- OS のインターフェース (装置に実在する eth や tap などの
				BROADCAST もの。要sudo。)
			- パイプ
			- L2 トンネル
		- 下位層から上がってきたイーサネットフレーム, LLC フレームと、
			宛先種別 (自分宛, BC/MC, 他人宛) とフレームデータを、
			フレームタイプ毎の上位層に渡す。
			- 他人宛は上位層に渡さず破棄する。
	- パイプ演算子での接続
		- 概要
			- ひとつの他インスタンスと接続する。
			- 対向できるのはひとつだけ。
			- 接続を切り替えるときは、まず抜いてから。
			- 上位層がある eth だと、パイプは下位層になる
			- 下位層がある eth だと、パイプは上位層になる
			- 上位層も下位層もある eth だと、パイプは付かない
		- 接続対象
			- L2 インターフェース (eth, vlan など)
			- bridge
			- L2 フィルター (firewall, qos など)

- vlan
	- 上位層との接続
		- 上位層からの送信を受け付ける
			- eth と同じ API で、同じデータを上位層から受け取る。
			- vlan-id を自分の id にして、VLAN ヘッダ部分だけを付けて
				下位層 eth/vlan に渡す
		- 下位層から上がってきたフレームのうち、vlan-id が合致するものを、
			フレームタイプ毎の上位層に渡す。
	- 下位層との接続
		- 接続対象
			- eth
			- vlan
	- パイプ演算子での接続
		- 概要
			- 各 vlan-id は、上位層あるいはパイプどっちかを持てる。
			- 下位層にはパイプは付かない
		- 接続対象
			- L2 インターフェース (eth, vlan など)
			- bridge
			- L2 filter
	- 備考
		- 802.1Q vlan, 802.1ad の外側タグなどを扱う。

- bridge
	- 概要
		- 複数の eth/vlan を束ねる。例としては L2 スイッチや、
			Linux の br インターフェースなどに相当する。
	- 上位層との接続
		- 上位層からの送信を受け付ける
			- eth と同じ API で、同じデータを上位層から受け取る。
			- 学習テーブルで下位層 eth/vlan を選び、送信する。
		- 下位層から上がってきたイーサネットフレーム, LLC フレームは
			- 送信元 MAC を一定期間だけ学習テーブルに保存する。
			- 宛先種別は、自分と eth/vlan たちのどれかの MAC と
				一致してれば「自分宛」として扱う。
			- 自分宛パケットは上位層に上げる。
			- BC/MC 宛パケットは、上位層に上げると同時に、
				転送=ON であれば下位層にも撒く。
			- 他人宛パケットは、転送=ON であれば、
				学習テーブルに沿って転送するか、あるいは下位層に撒く。
	- 下位層との接続
		- 接続対象
			- 複数の eth/vlan を収容する。
			- 各 eth/vlan の MAC も把握しておく。
	- 特殊機能
		- IGMP snooping
			- L3 機能だけど、L2 レベルで転送先の枝刈りができる。
		- BUM (Broadcst, Unknown Unicast, Multicast) 対策
			- ARP/NDP response を VXLAN などの独自プロトコルで
				各 bridge に配って事前学習させる。
			- ARP/NDP request を、MAC 管理サーバー行きインターフェース
				だけに送信する。あとは MAC 管理サーバーが頑張る。

- firewall
	- いろんなパケット種別を扱う。
		- ただし firewall 系インスタンスは自力でフレームの階層をたどるので、
			基本的に最下位の Ethernet frame を流すようにしておけばよい。
	- パケット送受信は左右一本ずつのパイプを使う。パイプ接続の都合上、
		パイプの左右インスタンスが扱うパケット種別を一致させる必要がある。
	- 市販の製品では、受信時/送信時でフィルタを区別しているものがある。
		NW-DIY firewall では右向きを forward, 左向きを backward として区別する。

- qos
	- 外部要件は firewall と同じ。

- IPv4 インターフェース
	- 概要
		- ARP, IPv4, ICMP/IPv4 パケットを扱う。
		- アドレスは 1 個だけ持つ。マスク長とセットで。
		- 上位層は router あるいは L4 系プロトコル (TCP, UDP など)
		- デフォルトゲートウェイを持つことができる。上位層が router なら
			使わないけど、そうじゃない時は役にたつ。
	- 上位層との接続
		- 上位層からの送信を受け付ける
			- 送信先 IPaddr と IP Data (と非必須な送信元 IPaddr) を受け取る。
			- 上位層が router なら、次ホップも受け取る。
			- 送信元アドレスは、上位層が言ってこなければ自分のアドレスを使う。
			- 送信先 IPaddr が自分のものなら、送信せず折り返す。
	- 下位層との接続
		- 接続対象
			- なし (生成初期などの一時的な状態。/dev/null)
			- eth/vlan/bridge
			- その他の OS インターフェース (P2P や tun)
			- パイプ
			- L3 トンネル (ipip など)
		- 下位層への送信
			- IP ヘッダを付けて、下位層に渡す。
			- IFF_NOARP フラグがなければ、次ホップあるいは送信先 IPaddr を
				ARP 解決して得た送信先 MAC を付けて渡す。
			- 送信先 IPaddr が自分宛なら、eth と同様。
			- 送信先 IPaddr が BC/MC なら、〃
		- 下位層から上がってきた IP/ARP data を受信する。
			ただしリダイレクトやルーティングは、上位層の router の設定次第。

			| L2宛先   | L3宛先       | 処理                 |
			|----------|--------------|----------------------|
			| 自分     | 自分         | 受信                 |
			| 自分     | 自サブネット | * リダイレクト       |
			| 自分     | 他サブネット | * ルーティング       |
			| 自分     | MC(参加)     | 受信, * ルーティング |
			| 自分     | MC(無視)     | 無視                 |
			| 他人     | *            | 無視                 |
			| MC(参加) | 自分         | 受信                 |
			| MC(参加) | 自サブネット | 無視                 |
			| MC(参加) | 他サブネット | 無視                 |
			| MC(参加) | MC(参加)     | 受信, * ルーティング |
			| MC(参加) | MC(無視)     | 無視                 |
			| MC(無視) | *            | 無視                 |
			| (P2P)    | 自分         | 受信                 |
			| (P2P)    | 他人         | * ルーティング       |
			| (P2P)    | MC(参加)     | 受信, * ルーティング |
			| (P2P)    | MC(無視)     | 無視                 |

		- 受信パケットは、プロトコル種別ごとの上位層に渡す。
			ただし ICMP は、ICMP error や NDP(IPv6) の都合があるので、
			自分で処理する。

- IPv6 インターフェース
	- IPv4 と同様

- NAT インターフェース
	- IPv4 や IPv6 インターフェース同様
	- 細かいこと言えば、src nat と dst nat と dst mat がある。
	- 細かいこと言えば、nat と napt がある。

- IPv4 host / router
	- 概要
		- 複数の IPv4 インターフェースを束ねる。
		- ルーティング ON/OFF 設定あり。
		- マルチキャストルーティング ON/OFF 設定あり。
	- 上位層との接続
		- 上位層からの送信を受け付ける
			- 送信先 IPaddr と IP Data (と非必須な送信元 IPaddr) を受け取る。
	- 下位層との接続
		- 接続対象は IPv4 インターフェースのみ。
		- 下位層への送信
			- 経路表から出力先インターフェースと次ホップを取り出して、
				そこに送信する。
			- 送信元のアドレスは、受け取らなかったら下位層のアドレスを使う。

- etherip
	- 概要
		- イーサネットフレームを IPv4/IPv6 でくるんで送受信する。
	- 上位層との接続
		- 上位層は eth
		- 上位層からの送信を受け付ける
			- Ethernet フレームを受け取る。
			- 設定されたリモート IPaddr に投げる
			- ローカル IPaddr は、下位層のものを使う。
	- 下位層との接続
		- 下位層は IP インターフェースあるいは router。
		- ローカル IPaddr は、下位層のものを使う。
			- 下位層が IP インターフェースなら、そのアドレスを使う。
			- 下位層が router なら、その下位層にある IP インターフェースから
				ひとつを選択し、そのアドレスを使う。

- vxlan
	- 外部要件は、下記を除き etherip と同じ。
	- vxlan id は、…
	- 対向先アドレスは、…

- TCP Conn
	- 上位層は、ストリーム。Ruby で言えば IO 相当。
		- 各ストリームは、ローカル/リモートの IPaddr/port で識別する。
	- 下位層は、IP インターフェース。
	- 概要
		- TCP 通信する
		- クライアントとしてこっちから接続するときは、
			識別子の 4 値を指定してインスタンス作成する。
			インスタンスは最初に 3 way handshake して、
			そのあとストリームとして使えるようになる。
		- TCP Listener で接続を受信するときは、
			識別子の 4 値と届いた SYN パケットでインスタンス生成する。
			インスタンスは最初に 3 way handshake の残りをやって、
			そのあとストリームとして使えるようになる。

- TCP Listener
	- 概要
		- TCP SYN を受けて TCP Conn を作る。
		- bind() と accept() みたいなもの。
	- 下位層は、IP インターフェースあるいは router (複数可)。
		- 特定のローカルポートで待ち受ける。
		- 届いた SYN の送信元 IPaddr,port, 宛先 IPaddr,port を上位に渡す。
	- 上位層は、ストリームを読み書きするインスタンスを作るための、
		インスタンス / クラス / メソッド / ...
		- 下位層からの SYN に対して TCP Conn を作る。

- UDP Listener, UDP Conn
	- 概要
		- TCP と同様。ただし 3 way handshake しない。

- MTCP
	- まだよく知らない。
