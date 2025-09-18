# frozen_string_literal: true

require 'foreman_tasks'

module ForemanResourceQuota
  class Engine < ::Rails::Engine
    engine_name 'foreman_resource_quota'

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
    initializer 'foreman_resource_quota.register_plugin', before: :finisher_hook do |app|
      app.reloader.to_prepare do
        require 'foreman_resource_quota/register'
      end
    end

    # Include concerns in this config.to_prepare block
    config.to_prepare do
      ::User.include ForemanResourceQuota::UserExtensions
      ::Usergroup.include ForemanResourceQuota::UsergroupExtensions
      ::Host::Managed.include ForemanResourceQuota::HostManagedExtensions

      # Controller extensions
      ::RegistrationCommandsController.prepend ForemanResourceQuota::Concerns::RegistrationCommandsControllerExtensions

      # Api controller extensions
      ::Api::V2::HostsController.include ForemanResourceQuota::Concerns::Api::V2::HostsControllerExtensions
      ::Api::V2::UsersController.include ForemanResourceQuota::Concerns::Api::V2::UsersControllerExtensions
      ::Api::V2::UsergroupsController.include ForemanResourceQuota::Concerns::Api::V2::UsergroupsControllerExtensions
    rescue StandardError => e
      Rails.logger.warn "ForemanResourceQuota: skipping engine hook (#{e})"
    end

    # Register ForemanTasks-based recurring logic/scheduled tasks
    initializer 'foreman_resource_quota.register_scheduled_tasks',
      before: :finisher_hook,
      after: :build_middleware_stack do |_app| # ForemanTasks::Task becomes only available after this hook
      action_paths = [ForemanResourceQuota::Engine.root.join('lib/foreman_resource_quota/async')]
      ::ForemanTasks.dynflow.config.eager_load_paths.concat(action_paths)

      # Skip object creation if the admin user is not present
      # skip database manipulations while tables do not exist, like in migrations
      if ActiveRecord::Base.connection.data_source_exists?(::ForemanTasks::Task.table_name) &&
         User.unscoped.find_by_login(User::ANONYMOUS_ADMIN).present?
        # Register the scheduled tasks
        ::ForemanTasks.dynflow.config.on_init(false) do |_world|
          ForemanResourceQuota::Engine.register_scheduled_task(
            ForemanResourceQuota::Async::RefreshResourceQuotaUtilization,
            '0 1 * * *'
          )
        end
      end
    rescue ActiveRecord::NoDatabaseError => e
      Rails.logger.warn "ForemanResourceQuota: skipping ForemanTasks registration hook (#{e})"
    end

    initializer 'foreman_resource_quota.register_gettext', after: :load_config_initializers do |_app|
      locale_dir = File.join(File.expand_path('../..', __dir__), 'locale')
      locale_domain = 'foreman_resource_quota'
      Foreman::Gettext::Support.add_text_domain locale_domain, locale_dir
    end

    # Helper to register ForemanTasks
    def self.register_scheduled_task(task_class, cronline)
      return if ::ForemanTasks::RecurringLogic.joins(:tasks)
                                              .merge(::ForemanTasks::Task.where(label: task_class.name))
                                              .exists?
      ::ForemanTasks::RecurringLogic.transaction(isolation: :serializable) do
        User.as_anonymous_admin do
          recurring_logic = ::ForemanTasks::RecurringLogic.new_from_cronline(cronline)
          recurring_logic.save!
          recurring_logic.start(task_class)
        end
      end
    rescue ActiveRecord::TransactionIsolationError => e
      Rails.logger.warn "ForemanResourceQuota: skipping RecurringLogic registration hook (#{e})"
    end
  end
end
