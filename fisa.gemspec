# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fisa/version'

Gem::Specification.new do |spec|
  spec.name          = "fisa"
  spec.version       = Fisa::VERSION
  spec.authors       = ["Eric Mill"]
  spec.email         = ["eric@konklone.com"]
  spec.description   = %q{Who watches the watchers?}
  spec.summary       = %q{This project "watches" the public docket of the FISC, and alerts the public and the administrator through tweets, emails, and texts upon any changes.}
  spec.homepage      = "https://github.com/konklone/fisa"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "git"
  spec.add_runtime_dependency "twitter"
  spec.add_runtime_dependency "pony"
  spec.add_runtime_dependency "twilio-rb"
  spec.add_runtime_dependency "bini"
  spec.add_runtime_dependency "slop"
end
