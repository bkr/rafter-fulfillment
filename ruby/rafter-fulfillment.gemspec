# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fulfillment/version'

Gem::Specification.new do |spec|
  spec.name           = "rafter-fulfillment"
  spec.version        = Fulfillment::VERSION
  spec.authors        = ["Michael Pearce", "Paolo Resmini", "Dudley Chamberlin", "Peter Myers", "Nick Zalabak", "Mike 'sealabcore' Taylor"]
  spec.email          = ["exchange-engineers@rafter.com"]
  spec.homepage       = "https://github.com/bkr/rafter-fulfillment"
  spec.summary        = "Client for the Rafter Fulfillment API"
  spec.license        = "Apache 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ["~> 2.11.0"]
  spec.add_development_dependency "pry"
  spec.add_development_dependency "faker"

  spec.add_runtime_dependency "curb"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "activesupport"
end
