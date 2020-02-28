# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'avsh/version'
require 'rake'

Gem::Specification.new do |spec|
  spec.name          = "avsh"
  spec.version       = Avsh::VERSION
  spec.authors       = ["Mason Malone"]
  spec.email         = ["mason@masonm.org"]

  spec.summary       = 'Faster alternative to "vagrant ssh", with extra features'
  spec.description   = <<-EOF
  avsh ("Augmented Vagrant sSH") is a standalone script that can be used in
  place of vagrant ssh. It provides greatly increased performance and several
  extra features.
  EOF
  spec.homepage      = "https://github.com/masonm/avsh"
  spec.license       = "MIT"

  spec.files         = FileList['lib/*.rb', 'spec/*.spec.rb']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "fakefs", "~> 0.8.1"
  spec.add_development_dependency "rubocop", "~> 0.75.1"
end
