# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gsrubylib/version"

Gem::Specification.new do |s|
  s.name        = "gsrubylib"
  s.version     = GS::VERSION
  s.authors     = ["Gavin Sinclair"]
  s.email       = ["gsinclair@gmail.com"]
  s.homepage    = ""
  s.summary     = "Some core methods I wish were built in + a small Label implementation"
  s.description = "Core methods like in? mapf indent trim not_nil? build_hash"
  s.licenses    = ["MIT"]

  s.rubyforge_project = ""
  s.has_rdoc = false

  s.files         = `git ls-files`.split("\n").reject { |x| x =~ /cheatsheet/i }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "pry", '~> 0'
  s.add_dependency "debuglog", '~> 0'

  s.add_development_dependency "bundler", '~> 0'
  s.add_development_dependency "whitestone", '~> 0'

  s.required_ruby_version = '>= 2.0'    # Assumed for now.
end
