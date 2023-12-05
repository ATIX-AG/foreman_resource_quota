# frozen_string_literal: true

module ForemanResourceQuota
  class Engine < ::Rails::Engine
    engine_name 'foreman_resource_quota'

    config.autoload_paths += Dir["#{config.root}/app/services/foreman_resource_quota"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/foreman_resource_quota"]
    config.autoload_paths += Dir["#{config.root}/app/controllers/foreman_resource_quota"]
    config.autoload_paths += Dir["#{config.root}/app/models/"]
    config.autoload_paths += Dir["#{config.root}/app/views/foreman_resource_quota"]

    # Add db migrations
    initializer 'foreman_resource_quota.load_app_instance_data' do |app|
      ForemanResourceQuota::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    # Apipie
    initializer 'foreman_resource_quota.apipie' do
      Apipie.configuration.checksum_path += ['/foreman_resource_quota/api/']
      Rabl.configure do |config|
        config.view_paths << ForemanResourceQuota::Engine.root.join('app', 'views', 'foreman_resource_quota')
      end
    end

    # Rake tasks
    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanResourceQuota::Engine.load_seed
      end
    end

    # Plugin extensions
    initializer 'foreman_resource_quota.register_plugin', before: :finisher_hook do |_app|
      require 'foreman_resource_quota/register'
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      ::User.include ForemanResourceQuota::UserExtensions
      ::Usergroup.include ForemanResourceQuota::UsergroupExtensions
      ::Host::Managed.include ForemanResourceQuota::HostManagedExtensions
    rescue StandardError => e
      Rails.logger.warn "ForemanResourceQuota: skipping engine hook (#{e})"
    end

    initializer 'foreman_resource_quota.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../..', __dir__), 'locale')
      locale_domain = 'foreman_resource_quota'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end
  end
end
