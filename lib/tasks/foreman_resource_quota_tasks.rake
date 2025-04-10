# frozen_string_literal: true

require 'rake/testtask'

# Tasks
namespace :foreman_resource_quota do
  desc 'EXPERIMENTAL: Revert all database migrations of this plugin, preparing plugin uninstall'
  task revert_db_migrations: :environment do
    plugin = Foreman::Plugin.find ForemanResourceQuota.name.underscore
    ActiveRecord::MigrationContext.new(plugin.migrations_paths, ActiveRecord::SchemaMigration).down
  end
end

# Tests
namespace :test do
  desc 'Test ForemanResourceQuota'
  Rake::TestTask.new(:foreman_resource_quota) do |t|
    test_dir = File.join(__dir__, '..', '..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.test_files = [Rails.root.join('test/unit/foreman/access_permissions_test.rb')]
    t.verbose = true
    t.warning = false
  end
end

namespace :foreman_resource_quota do
  task rubocop: :environment do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_resource_quota) do |task|
        task.patterns = ["#{ForemanResourceQuota::Engine.root}/app/**/*.rb",
                         "#{ForemanResourceQuota::Engine.root}/lib/**/*.rb",
                         "#{ForemanResourceQuota::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_resource_quota'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_resource_quota']

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance ['test:foreman_resource_quota', 'foreman_resource_quota:rubocop']
end
