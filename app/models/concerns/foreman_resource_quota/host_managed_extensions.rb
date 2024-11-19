# frozen_string_literal: true

module ForemanResourceQuota
  module HostManagedExtensions
    extend ActiveSupport::Concern
    include ForemanResourceQuota::ResourceQuotaHelper
    include ForemanResourceQuota::Exceptions

    included do
      validate :check_resource_quota_capacity

      belongs_to :resource_quota, class_name: '::ForemanResourceQuota::ResourceQuota'
      has_one :resource_quota_missing_resources, class_name: '::ForemanResourceQuota::ResourceQuotaMissingHost',
        inverse_of: :missing_host, foreign_key: :missing_host_id, dependent: :destroy
      scoped_search relation: :resource_quota, on: :name, complete_value: true, rename: :resource_quota
    end

    def check_resource_quota_capacity
      handle_quota_check
      true
    rescue ResourceQuotaException => e
      handle_error('resource_quota_id',
        e.bare_message,
        format('An error occured while checking the resource quota capacity: %s', e))
    rescue Foreman::Exception => e
      handle_error(:base,
        e.bare_message,
        format('An unexpected Foreman error occured while checking the resource quota capacity: %s', e))
    rescue StandardError => e
      handle_error(:base,
        e.message,
        format('An unknown error occured while checking the resource quota capacity: %s', e))
    end

    private

    def handle_quota_check
      return if early_return?
      quota_utilization = determine_quota_utilization
      host_resources = determine_host_resources
      verify_resource_quota_limits(quota_utilization, host_resources)
    end

    def handle_error(error_module, error_message, log_message)
      errors.add(error_module, error_message)
      Rails.logger.error(N_(log_message))
      false
    end

    def determine_quota_utilization(quota)
      missing_hosts = quota.missing_hosts(exclude: [name])
      unless missing_hosts.empty?
        raise ResourceQuotaUtilizationException,
          "Resource Quota '#{quota.name}' cannot determine resources for #{missing_hosts.size} hosts."
      end
      quota.utilization(exclude: [name])
    end

    def determine_host_resources(active_resources)
      new_host_resources, missing_hosts = call_utilization_helper(active_resources, [self])
      if missing_hosts.key?(name) || missing_hosts.key?(name.to_sym)
        raise HostResourcesException,
          "Cannot determine host resources for #{name}: #{missing_hosts[name]}"
      end
      host_resources.resources = new_host_resources
      host_resources.resources
    end

    def check_resource_quota_limits(quota, quota_utilization, current_host_resources)
      quota_utilization.each do |resource_type, resource_utilization|
        next if resource_utilization.nil?

        max_quota = quota[resource_type]
        all_hosts_utilization = resource_utilization + current_host_resources[resource_type.to_sym]
        next if all_hosts_utilization <= max_quota

        raise ResourceLimitException, formulate_limit_error(quota.name, resource_utilization,
          all_hosts_utilization, max_quota, resource_type)
      end
    end

    def formulate_limit_error(quota_name, resource_utilization, all_hosts_utilization, max_quota, resource_type)
      if resource_utilization <= max_quota
        N_(format("Host exceeds %s limit of '%s'-quota by %s (max. %s)",
          natural_resource_name_by_type(resource_type),
          quota_name,
          resource_value_to_string(all_hosts_utilization - max_quota, resource_type),
          resource_value_to_string(max_quota, resource_type)))
      else
        N_(format("%s limit of '%s'-quota is already exceeded by %s without adding the new host (max. %s)",
          natural_resource_name_by_type(resource_type),
          quota_name,
          resource_value_to_string(resource_utilization - max_quota, resource_type),
          resource_value_to_string(max_quota, resource_type)))
      end
    end

    def formulate_resource_inconsistency_error(quota_name, resource_type, quota_utilization_value, resource_value)
      N_("Resource Quota '#{quota_name}' inconsistency detected while destroying host '#{name}':\n" \
         "Resource Quota #{resource_type} current utilization: #{quota_utilization_value}.\n" \
         "Host resource value: #{resource_value}.\n" \
         'Skipping.')
    end

    def formulate_quota_inconsistency_error(quota_name)
      N_("An error occured adapting the resource quota utilization of '#{quota_name}' " \
         "while processing host '#{name}'. The resource quota utilization values might be inconsistent.")
    end

    def early_return?(quota)
      if quota.nil?
        return true if quota_assigment_optional?
        raise HostResourceQuotaEmptyException, 'must be given.'
      end
      return true if quota.active_resources.empty?
      return true if Setting[:resource_quota_global_no_action] # quota is assigned, but not supposed to be checked
      false
    end

    def quota_assigment_optional?
      owner.resource_quota_is_optional || Setting[:resource_quota_optional_assignment]
    end

    # Wrap into a function for easier testing
    def call_utilization_helper(resources, hosts)
      all_host_resources, missing_hosts = utilization_from_resource_origins(resources, hosts)
      unless all_host_resources.key?(name)
        raise HostResourcesException,
          "Host #{name} was not included when determining host resources."
      end
      current_host_resources = all_host_resources[name]
      [current_host_resources, missing_hosts]
    end
  end
end
