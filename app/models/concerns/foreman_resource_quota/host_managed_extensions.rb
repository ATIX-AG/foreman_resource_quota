# frozen_string_literal: true

module ForemanResourceQuota
  module HostManagedExtensions
    extend ActiveSupport::Concern
    include ForemanResourceQuota::ResourceQuotaHelper
    include ForemanResourceQuota::Exceptions

    included do
      validate :verify_resource_quota

      has_one :host_resources, class_name: '::ForemanResourceQuota::HostResources',
        inverse_of: :host, foreign_key: :host_id, dependent: :destroy
      has_one :resource_quota_host, class_name: '::ForemanResourceQuota::ResourceQuotaHost',
        inverse_of: :host, foreign_key: :host_id, dependent: :destroy
      has_one :resource_quota, class_name: '::ForemanResourceQuota::ResourceQuota',
        through: :resource_quota_host
      scoped_search relation: :resource_quota, on: :name, complete_value: true, rename: :resource_quota

      # A host shall always have a .host_resources attribute
      before_validation :build_host_resources, unless: -> { host_resources.present? }
    end

    def verify_resource_quota
      handle_quota_check(resource_quota)
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

    def resource_quota_id
      resource_quota&.id
    end

    def resource_quota_id=(val)
      if val.blank?
        resource_quota_host&.destroy
      else
        quota = ForemanResourceQuota::ResourceQuota.find_by(id: val)
        raise ActiveRecord::RecordNotFound, "ResourceQuota with ID \"#{val}\" not found" unless quota
        self.resource_quota = quota
      end
    end

    private

    def handle_quota_check(quota)
      return if early_return?(quota)
      quota_utilization = determine_quota_utilization(quota)
      current_host_resources = determine_host_resources(quota.active_resources)
      check_resource_quota_limits(quota, quota_utilization, current_host_resources)
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
