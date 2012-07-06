# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "yell/adapters/gelf/version"

Gem::Specification.new do |s|
  s.name        = "yell-adapters-gelf"
  s.version     = Yell::Adapters::Gelf::VERSION
  s.authors     = ["Rudolf Schmidt"]

  s.homepage    = "http://rubygems.org/gems/yell"
  s.summary     = %q{Yell - Your Extensible Logging Library }
  s.description = %q{Graylog2 adapter for Yell}

  s.rubyforge_project = "yell"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "yell", ">= 0.12.0"
  s.add_runtime_dependency "json"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rr"
end

