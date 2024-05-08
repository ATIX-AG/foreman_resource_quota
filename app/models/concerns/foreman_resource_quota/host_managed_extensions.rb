# frozen_string_literal: true

module ForemanResourceQuota
  module HostManagedExtensions
    extend ActiveSupport::Concern
    include ForemanResourceQuota::ResourceQuotaHelper
    include ForemanResourceQuota::Exceptions

    included do
      validate :verify_resource_quota_on_create, if: -> { new_record? }
      validate :verify_resource_quota_on_change, if: -> { resource_quota_id_change_to_be_saved && !new_record? }
      after_create -> { add_host_capacity_to_quota(resource_quota) }
      before_destroy -> { remove_host_capacity_from_quota(resource_quota) }

      belongs_to :resource_quota, class_name: '::ForemanResourceQuota::ResourceQuota'
      has_one :resource_quota_missing_resources, class_name: '::ForemanResourceQuota::ResourceQuotaMissingHost',
        inverse_of: :missing_host, foreign_key: :missing_host_id, dependent: :destroy
      scoped_search relation: :resource_quota, on: :name, complete_value: true, rename: :resource_quota
    end

    def verify_resource_quota_on_create
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

    # rubocop:disable Metrics/AbcSize
    def verify_resource_quota_on_change
      from_quota_id, to_quota_id = resource_quota_id_change_to_be_saved
      from_quota = ResourceQuota.find_by(id: from_quota_id)
      to_quota = ResourceQuota.find_by(id: to_quota_id)

      remove_host_capacity_from_quota(from_quota) unless from_quota.nil?
      handle_quota_check(to_quota) unless to_quota.nil?
      add_host_capacity_to_quota(to_quota) unless to_quota.nil?
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
    # rubocop:enable Metrics/AbcSize

    private

    def handle_quota_check(quota)
      return if early_return?(quota)
      quota_utilization = determine_quota_utilization(quota)
      host_resources = determine_host_resources(quota.active_resources)
      verify_resource_quota_limits(quota, quota_utilization, host_resources)
    end

    def handle_error(error_module, error_message, log_message)
      errors.add(error_module, error_message)
      Rails.logger.error(N_(log_message))
      false
    end

    def determine_quota_utilization(quota)
      missing_hosts = quota.missing_hosts
      unless missing_hosts.empty?
        raise ResourceQuotaUtilizationException,
          "Resource Quota '#{quota.name}' cannot determine resources for #{missing_hosts.size} hosts."
      end
      quota.utilization
    end

    def determine_host_resources(active_resources)
      (host_resources, missing_hosts) = call_utilization_helper(active_resources, [self])
      unless missing_hosts.empty?
        raise HostResourcesException,
          "Cannot determine host resources for #{name}"
      end
      host_resources
    end

    def verify_resource_quota_limits(quota, quota_utilization, host_resources)
      quota_utilization.each do |resource_type, resource_utilization|
        next if resource_utilization.nil?

        max_quota = quota[resource_type]
        all_hosts_utilization = resource_utilization + host_resources[resource_type.to_sym]
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

    def add_host_capacity_to_quota(quota)
      return if quota.nil?

      update_quota_with_host_resources(quota) do |quota_resource_utilization, resource_value, _|
        quota_resource_utilization + resource_value
      end
    end

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
