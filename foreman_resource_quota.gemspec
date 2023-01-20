require File.expand_path('../lib/foreman_resource_quota/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'foreman_resource_quota'
  s.version     = ForemanPluginTemplate::VERSION
  s.metadata    = { "is_foreman_plugin" => "true" }
  s.license     = 'GPL-3.0'
  s.authors     = ['TODO: Your name']
  s.email       = ['TODO: Your email']
  s.homepage    = 'TODO'
  s.summary     = 'TODO: Summary of ForemanPluginTemplate.'
  # also update locale/gemspec.rb
  s.description = 'TODO: Description of ForemanPluginTemplate.'

  s.files = Dir['{app,config,db,lib,locale,webpack}/**/*'] + ['LICENSE', 'Rakefile', 'README.md', 'package.json']
  s.test_files = Dir['test/**/*'] + Dir['webpack/**/__tests__/*.js']

  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rdoc'
end
