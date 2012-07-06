# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "yell-adapters-gelf"
  s.version     = "0.11.0"
  s.authors     = ["Rudolf Schmidt"]

  s.homepage    = "http://rubygems.org/gems/yell"
  s.summary     = %q{Yell - Your Extensible Logging Library }
  s.description = %q{Graylog2 adapter for Yell}

  s.rubyforge_project = "yell"

  s.files         = `git ls-files`.split("\n")
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})

  s.require_paths = ["lib"]

  s.add_runtime_dependency "yell", ">= 0.13.0"
  s.add_runtime_dependency "json"
end

