# frozen_string_literal: true

require File.expand_path('lib/foreman_resource_quota/version', __dir__)

Gem::Specification.new do |s|
  s.name        = 'foreman_resource_quota'
  s.version     = ForemanResourceQuota::VERSION
  s.metadata    = { 'is_foreman_plugin' => 'true' }
  s.license     = 'GPL-3.0'
  s.authors     = ['Bastian Schmidt']
  s.email       = ['schmidt@atix.de']
  s.homepage    = 'https://github.com/ATIX-AG/foreman_resource_quota'
  s.summary     = 'Foreman Plug-in for resource quota'
  # also update locale/gemspec.rb
  s.description = 'Foreman Plug-in to manage resource usage among users.'

  s.files = Dir['{app,config,db,lib,locale,webpack}/**/*'] + ['LICENSE', 'Rakefile', 'README.md', 'package.json']

  s.add_dependency 'foreman-tasks', '>= 10.0', '< 11'

  s.add_development_dependency 'theforeman-rubocop', '~> 0.1.2'
end
