# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'strand/version'

Gem::Specification.new do |gem|
  gem.name          = "strand"
  gem.version       = Strand::VERSION
  gem.authors       = ["Grant Gardner","Christopher J. Bottaro"]
  gem.email         = ["grant@lastweekend.com.au", "cjbottaro@alumni.cs.utexas.edu"]
  gem.description   = %q{Get thread-like behavior from fibers using EventMachine.}
  gem.summary       = %q{Make fibers behave like threads using EventMachine}
  gem.homepage      = "http://rubygems.org/gems/strand"
  gem.files         = `git ls-files`.split($/)
  gem.test_files    = `git ls-files -- {test,spec}/*`.split($/)
  gem.require_paths = ["lib"]
  gem.licenses      = %q{MIT}

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'em-spec'
  gem.add_development_dependency 'rr'
  gem.add_development_dependency 'eventmachine', '~> 0.12.0'
end
