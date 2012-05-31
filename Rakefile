require 'rubygems'
require 'rake'

desc 'Default: run unit tests'
task :default => :test

begin
  require 'rspec'
  require 'rspec/core/rake_task'
  desc 'Run the unit tests'
  RSpec::Core::RakeTask.new(:test)
rescue LoadError
  task :test do
    raise "You must have rspec 2.0 installed to run the tests"
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "tribune-cobranding"
    gem.summary = %Q{Provides Rails view layouts from an HTTP service}
    gem.description = %Q{Provides Rails view layouts from an HTTP service.}
    gem.authors = ["Brian Durand"]
    gem.email = ["bdurand@tribune.com"]
    gem.files = FileList["lib/**/*", "spec/**/*", "README.rdoc", "Rakefile", "TRIBUNE_CODE"].to_a
    gem.has_rdoc = true
    gem.rdoc_options << '--line-numbers' << '--inline-source' << '--main' << 'README.rdoc'
    gem.extra_rdoc_files = ["README.rdoc"]
    gem.add_dependency('actionpack', '>=3.0.0')
    gem.add_dependency('rest-client')
    gem.add_development_dependency('rspec', '>= 2.0.0')
    gem.add_development_dependency('webmock')
  end
rescue LoadError
end
