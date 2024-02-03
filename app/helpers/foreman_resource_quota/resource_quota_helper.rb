# frozen_string_literal: true

module ForemanResourceQuota
  module ResourceQuotaHelper
    FACTOR_B_TO_KB = 1024
    FACTOR_B_TO_MB = 1024 * 1024
    FACTOR_B_TO_GB = 1024 * FACTOR_B_TO_MB

    def natural_resource_name_by_type(resource_type)
      type_names = { cpu_cores: 'CPU cores', memory_mb: 'Memory', disk_gb: 'Disk space' }
      key = resource_type.is_a?(String) ? resource_type.to_sym : resource_type
      raise "No natural name for unknown resource type '#{resource_type}'" unless type_names.key?(key)
      type_names[key]
    end

    def units_by_type(resource_type)
      type_units = {
        cpu_cores: [
          { symbol: 'cores', factor: 1 },
        ],
        memory_mb: [
          { symbol: 'MB', factor: 1 },
          { symbol: 'GB', factor: FACTOR_B_TO_KB },
          { symbol: 'TB', factor: FACTOR_B_TO_MB },
        ],
        disk_gb: [
          { symbol: 'GB', factor: 1 },
          { symbol: 'TB', factor: FACTOR_B_TO_KB },
          { symbol: 'PB', factor: FACTOR_B_TO_MB },
        ],
      }
      key = resource_type.to_sym
      raise "No units for unknown resource type '#{resource_type}'" unless type_units.key?(key)
      type_units[key]
    end

    def find_largest_unit(resource_value, units)
      units.reverse_each do |unit|
        return unit.values_at(:symbol, :factor) if resource_value >= unit[:factor]
      end
      units[0].values_at(:symbol, :factor)
    end

    def resource_value_to_string(resource_value, resource_type)
      (symbol, factor) = find_largest_unit(resource_value, units_by_type(resource_type))
      unit_applied_value = (resource_value / factor).round(1)
      format_text = if (unit_applied_value % 1).zero?
                      '%.0f %s'
                    else
                      '%.1f %s'
                    end
      format(format_text, unit_applied_value, symbol)
    end

    def utilization_from_resource_origins(resources, hosts, custom_resource_origins: nil)
      utilization_sum = resources.each.with_object({}) { |key, hash| hash[key] = 0 }
      missing_hosts_resources = create_missing_hosts_resources_hash(hosts, resources)
      hosts_hash = hosts.index_by(&:name)
      resource_classes = custom_resource_origins || default_resource_origin_classes
      resource_classes.each do |origin_class|
        origin_class.new.collect_resources!(
          utilization_sum,
          missing_hosts_resources,
          hosts_hash
        )
      end

      [utilization_sum, missing_hosts_resources]
    end

    private

    # Create a Hash that maps resources to host names.
    # { <host name>: [<list of to be determined resources>] }
    #     for example:
    #     {
    #       "host_a": {
    #         [ :cpu_cores, :disk_gb ]
    #       },
    #       "host_b": {
    #         [ :cpu_cores, :disk_gb ]
    #       },
    # Parameters:
    #   - hosts: Array of host objects.
    #   - resources: Array of resources (as symbol, e.g. [:cpu_cores, :disk_gb]).
    # Returns: Hash with host names as keys and resources as values.
    def create_missing_hosts_resources_hash(hosts, resources)
      return {} if hosts.empty? || resources.empty?

      resources_to_determine = resources.compact
      return {} if resources_to_determine.empty?

      hosts.map(&:name).index_with { resources_to_determine.clone }
    end

    # Default classes that are used to determine host resources. Determines
    # resources in the order of this list.
    def default_resource_origin_classes
      [
        ResourceOrigins::ComputeResourceOrigin,
        ResourceOrigins::VMAttributesOrigin,
        ResourceOrigins::ComputeAttributesOrigin,
        ResourceOrigins::FactsOrigin,
      ]
    end
  end
end
