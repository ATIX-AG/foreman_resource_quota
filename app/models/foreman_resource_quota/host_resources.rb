# frozen_string_literal: true

module ForemanResourceQuota
  class HostResources < ApplicationRecord
    self.table_name = 'hosts_resources'

    belongs_to :resource_quota, class_name: 'ResourceQuota'
    belongs_to :host, class_name: '::Host::Managed', unqiue: true
    // Talk to Manisha regarding mico-service SQL relation
    -> For some reasion, when adding a host like my_quota.hosts << [some_host_a, some_host_b] results in NEW HostResources entries
    -> See the test on the right

    def resources
      {
        cpu_cores: self.cpu_cores,
        memory_mb: self.memory_mb,
        disk_gb: self.disk_gb,
      }
    end

    def resources=(val)
      allowed_attributes = val.slice(:cpu_cores, :memory_mb, :disk_gb)
      assign_attributes(allowed_attributes) # Set multiple attributes at once (given a hash)
    end

    # Return a Array of unknown host resources (returns an empty Array if all are known)
    # For example, completely unknown host resources returns:
    #   [
    #     :cpu_cores,
    #     :memory_mb,
    #     :disk_gb,
    #   ]
    def missing_resources(use_active_resources: true)
      empty_resources = []
      resources_to_check = [:cpu_cores, :memory_mb, :disk_gb]
      resources_to_check = self.resource_quota.active_resources if use_active_resources && self.resource_quota.present?

      resources_to_check.each do |single_resource|
        empty_resources << single_resource if self.send(single_resource).nil?
      end

      empty_resources
    end
  end
end
