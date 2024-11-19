# frozen_string_literal: true

module ForemanResourceQuota
  class HostResources < ApplicationRecord
    self.table_name = 'hosts_resources'

    belongs_to :host, class_name: '::Host::Managed'
    validates :host, { presence: true, uniqueness: true }

    def resources
      {
        cpu_cores: cpu_cores,
        memory_mb: memory_mb,
        disk_gb: disk_gb,
      }
    end

    def resources=(val)
      allowed_attributes = val.slice(:cpu_cores, :memory_mb, :disk_gb)
      assign_attributes(allowed_attributes) # Set multiple attributes at once (given a hash)
    end

    # Returns an array of unknown host resources (returns an empty array if all are known)
    # For example, completely unknown host resources returns:
    #   [
    #     :cpu_cores,
    #     :memory_mb,
    #     :disk_gb,
    #   ]
    # Consider only the resource_quota's active resources by default.
    def missing_resources(only_active_resources: true)
      empty_resources = []
      resources_to_check = %i[cpu_cores memory_mb disk_gb]
      resources_to_check = host.resource_quota.active_resources if only_active_resources && host.resource_quota.present?

      resources_to_check.each do |single_resource|
        empty_resources << single_resource if send(single_resource).nil?
      end

      empty_resources
    end
  end
end
