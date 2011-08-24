# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{strand}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Christopher J. Bottaro}]
  s.date = %q{2011-08-24}
  s.description = %q{Get thread-like behavior from fibers using EventMachine.}
  s.email = %q{cjbottaro@alumni.cs.utexas.edu}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/strand.rb",
    "lib/strand/atc.rb",
    "lib/strand/condition_variable.rb",
    "spec/condition_variable_spec.rb",
    "spec/spec_helper.rb",
    "test/helper.rb",
    "test/test_strand.rb"
  ]
  s.homepage = %q{http://github.com/cjbottaro/strand}
  s.licenses = [%q{MIT}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.7}
  s.summary = %q{Make fibers behave like threads using EventMachine.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<em-spec>, [">= 0"])
      s.add_development_dependency(%q<eventmachine>, ["~> 0.12.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<rr>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<em-spec>, [">= 0"])
      s.add_dependency(%q<eventmachine>, ["~> 0.12.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<rr>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<em-spec>, [">= 0"])
    s.add_dependency(%q<eventmachine>, ["~> 0.12.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<rr>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
