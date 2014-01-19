# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crew/version'

Gem::Specification.new do |spec|
  spec.name          = "crew"
  spec.version       = Crew::VERSION
  spec.authors       = ["Josh Hull"]
  spec.email         = ["joshbuddy@gmail.com"]
  spec.description   = %q{Write semantic scripts to setup and control your computer}
  spec.summary       = %q{Write semantic scripts to setup and control your computer.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "pry", "~>0.9.12.2"
  spec.add_dependency "trollop", "2.0"
  spec.add_dependency "nokogiri", "~>1.6.0"
  spec.add_dependency "rainbow", "~>1.1.4"
  spec.add_dependency "net-ssh", "~>2.7.0"
  spec.add_dependency "net-scp", "~>1.1.2"
  spec.add_dependency "json", "~> 1.8.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "mocha", "~>0.14.0"
end
