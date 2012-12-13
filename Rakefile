require "bundler/gem_tasks"

require 'rspec/core'
require 'rspec/core/rake_task'
require 'rdoc/task'
require 'rake/clean'

RSpec::Core::RakeTask.new(:spec)

RDoc::Task.new do |rdoc|
    rdoc.main = "README.rdoc"
    rdoc.rdoc_files.include("README.rdoc", "CHANGELOG","lib/**/*.rb")
    rdoc.title = "Strand"
end

CLOBBER.include [ "pkg/" ]

