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
      has_one :resource_quota, class_name: '::ForemanResourceQuota::ResourceQuota',
        through: :host_resources
      scoped_search relation: :resource_quota, on: :name, complete_value: true, rename: :resource_quota
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

    # A host shall always have a .host_resources attribute
    def host_resources
      super || build_host_resources
    end

    def resource_quota=(val)
      if val.is_a?(ForemanResourceQuota::ResourceQuota)
        super(val)
      else
        resource_quota = ForemanResourceQuota::ResourceQuota.find_by(id: val)
        if resource_quota
          super(resource_quota)
        else
          errors.add(:resource_quota, "not found for ID: #{val}")
        end
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
      missing_hosts = quota.missing_hosts(exclude: [self.name])
      unless missing_hosts.empty?
        raise ResourceQuotaUtilizationException,
          "Resource Quota '#{quota.name}' cannot determine resources for #{missing_hosts.size} hosts."
      end
      quota.utilization(exclude: [self.name])
    end

    def determine_host_resources(active_resources)
      # TODO: Evaluate, check host resources or just rely on host.host_resources?
      #   - Problem:
      #     on every save, the host resources are determined which makes the process slower
      #   - Solution:
      #     Check if resources exist, only determine if they don't
      #   - Potential Issue:
      #     A user adds another hard disk and that is not "recognized", just when re-calculating the whole quota resources
      all_host_resources, missing_hosts = call_utilization_helper(active_resources, [self])
      current_host_resources = all_host_resources[self.name]
      if missing_hosts.has_key?(self.name)
        raise HostResourcesException,
          "Cannot determine host resources for #{name}: #{missing_hosts[name]}"
      end
      self.host_resources.resources = current_host_resources
      self.host_resources.resources
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
      if resource_utilization < max_quota
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
      utilization_from_resource_origins(resources, hosts)
    end

    # TODO: Might not be necessary anymore?
    def add_host_capacity_to_quota(quota)
      return if quota.nil?

      update_quota_with_host_resources(quota) do |quota_resource_utilization, resource_value, _|
        quota_resource_utilization + resource_value
      end
    end

    # TODO: Might not be necessary anymore?
    def remove_host_capacity_from_quota(quota)
      return if quota.nil?

      update_quota_with_host_resources(quota) do |quota_resource_utilization, resource_value, resource_type|
        quota_resource_utilization - helper_resource_value_subtraction(
          quota.name,
          resource_value,
          quota_resource_utilization,
          resource_type
        )
      end
    end

    # TODO: Might not be necessary anymore?
    def update_quota_with_host_resources(quota)
      host_resources = determine_host_resources(quota.active_resources)
      new_utilization = quota.utilization

      host_resources.each do |resource_type, resource_value|
        new_utilization[resource_type] ||= 0
        new_utilization[resource_type] = yield(new_utilization[resource_type], resource_value, resource_type)
      end

      quota.utilization = new_utilization
    rescue ResourceQuotaException => e
      Rails.logger.warn("#{formulate_quota_inconsistency_error(quota.name)}\n#{e.bare_message}")
    end

    # TODO: Might not be necessary anymore?
    def helper_resource_value_subtraction(quota_name, host_resource_value, quota_value, resource_type)
      return host_resource_value if quota_value >= host_resource_value

      # Log inconsistency warning and don't subtract anything from quota utilization value
      Rails.logger.warn(formulate_quota_inconsistency_error(quota_name, resource_type,
        new_utilization[resource_type],
        host_resource_value))
      0
    end
  end
end
