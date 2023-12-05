# frozen_string_literal: true

module ForemanResourceQuota
  module ResourceQuotaHelper
    FACTOR_B_TO_MB = 1024 * 1024
    FACTOR_B_TO_GB = 1024 * FACTOR_B_TO_MB

    def natural_resource_name_by_type(type)
      type_names = { cpu_cores: 'CPU cores', memory_mb: 'Memory (MB)', disk_gb: 'Disk space (GB)' }
      type_names[type]
    end

    def build_missing_resources_per_host_list(hosts, quota_utilization)
      # missing_res_per_host := { <host_id>: [<list of to be determined resources>] }
      # for example: { 1: [ :disk_gb ], 2: [ :cpu_cores, :disk_gb ] }
      return {} if hosts.empty? || quota_utilization.empty?

      missing_res_per_host = hosts.map(&:id).index_with { [] }
      missing_res_per_host.each_key do |host_id|
        quota_utilization.each do |resource|
          missing_res_per_host[host_id] << resource unless resource.nil?
        end
      end
      missing_res_per_host
    end

    def utilization_from_resource_origins(resources, hosts, use_compute_resource: true, use_vm_attributes: true,
                                          use_facts: true)
      utilization = resources.each.with_object({}) { |key, hash| hash[key] = 0 }
      missing_res_per_host = build_missing_resources_per_host_list(hosts, resources)

      if use_compute_resource
        ResourceOrigin::ComputeResourceOrigin.new.collect_resources!(utilization, missing_res_per_host)
      end
      ResourceOrigin::VMAttributesOrigin.new.collect_resources!(utilization, missing_res_per_host) if use_vm_attributes
      ResourceOrigin::FactsOrigin.new.collect_resources!(utilization, missing_res_per_host) if use_facts

      [utilization, missing_res_per_host]
    end
  end
end
