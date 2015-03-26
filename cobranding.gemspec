# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cobranding/version'
Gem::Specification.new do |spec|
  spec.name          = 'cobranding'
  spec.version       = Cobranding::VERSION
  spec.authors       = ['Brian Durand', 'Milan Dobrota']
  spec.email         = ['mdobrota@tribpub.com']
  spec.summary       = 'Provides Rails view layouts from an HTTP service'
  spec.description   = 'Provides Rails view layouts from an HTTP service.'
  spec.homepage      = ''

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'actionpack', '>= 3.0.0'
  spec.add_runtime_dependency 'rest-client', '>= 0'

  spec.add_development_dependency 'rspec', '~> 2.8.0'
  spec.add_development_dependency 'webmock', '~> 1.7.7'
  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
