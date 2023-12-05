# frozen_string_literal: true

module ForemanResourceQuota
  module HostManagedExtensions
    extend ActiveSupport::Concern
    include ResourceQuotaHelper

    included do
      validate :check_resource_quota_capacity

      belongs_to :resource_quota, class_name: '::ForemanResourceQuota::ResourceQuota'
      scoped_search relation: :resource_quota, on: :name, complete_value: true, rename: :resource_quota
    end

    # rubocop: disable Metrics/AbcSize
    def check_resource_quota_capacity
      return errors.empty? if early_return?

      resource_quota.determine_utilization([self])
      unless resource_quota.missing_hosts.empty?
        errors.add(:resource_quota,
          N_(format('An error occured reading host resources. Check the foreman error log.')))
        return false
      end

      verify_resource_quota_limits(resource_quota.utilization)
      errors.empty?
    end
    # rubocop: enable Metrics/AbcSize

    private

    def verify_resource_quota_limits(quota_utilization)
      quota_utilization.each do |type, utilization|
        next if utilization.nil?
        max_quota = resource_quota[type]
        next if utilization <= max_quota
        errors.add(:resource_quota, N_(format("Host resources exceed quota '%s' for %s: %s > %s",
          resource_quota_name,
          natural_resource_name_by_type(type),
          utilization,
          max_quota)))
        break
      end
    end

    def early_return?
      if resource_quota.nil?
        return true if quota_assigment_optional?
        errors.add(:resource_quota, 'must be given.')
        return true
      end
      return true if Setting[:resource_quota_global_no_action] # quota is assigned, but not supposed to be checked
      false
    end

    def quota_assigment_optional?
      owner.resource_quota_is_optional || owner.admin || Setting[:resource_quota_global_optional_user_assignment]
    end
  end
end
