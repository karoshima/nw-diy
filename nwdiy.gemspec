# -*- mode: ruby; coding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nwdiy/version"

Gem::Specification.new do |spec|
  spec.name          = "nwdiy"
  spec.version       = Nwdiy::VERSION
  spec.authors       = ["KASHIMA Hiroaki"]
  spec.email         = ["kashima@jp.fujitsu.com"]

  spec.summary       = "Feel free to use/read/modify network functions."
  spec.description   = "Feel free to use use/read/modify network functions.
Feel free to DO-IT-YOURSELF your new network functions.

(to be translate into english.)
この NW-DIY は、ネットワーク機能を気軽に試してみるためのライブラリ群です。
「性能を追求しない」「ハード制約なし」「OS制約なし」と割り切ることで、
ハードウェアやカーネルなどの複雑な知識を前提とすることなく、スクリプトを組む
程度の軽い感覚でネットワーク機能を作ったり改造したりすることができます。"

  spec.homepage      = "http://github.com/karoshima/nw-diy.git"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
