# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec-rcv/version'

Gem::Specification.new do |spec|
  spec.name          = "rspec-rcv"
  spec.version       = RSpecRcv::VERSION
  spec.authors       = ["Stephen Bussey"]
  spec.email         = ["steve.bussey@salesloft.com"]

  spec.summary       = %q{Export results of rspec tests to disk for integration testing.}
  spec.homepage      = "https://github.com/SalesLoft/rspec-rcv"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "rspec"
  spec.add_runtime_dependency "diffy"
end
