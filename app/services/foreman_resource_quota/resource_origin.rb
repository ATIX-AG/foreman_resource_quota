# frozen_string_literal: true

module ForemanResourceQuota
  class ResourceOrigin
    RESOURCE_FUNCTION_MAP = {
      cpu_cores: :extract_cpu_cores,
      memory_mb: :extract_memory_mb,
      disk_gb: :extract_disk_gb,
    }.freeze

    def collect_resources!(hosts_resources, missing_hosts_resources, host_objects)
      return if missing_hosts_resources.empty?

      relevant_hosts = load_hosts_eagerly(missing_hosts_resources, host_objects, host_attribute_eager_name)
      host_values = collect_attribute_from_hosts(relevant_hosts, host_attribute_name)
      process_resources_and_delete_missing_hosts!(hosts_resources, missing_hosts_resources, host_values)
    end

    def host_attribute_eager_name
      raise NotImplementedError
    end

    def host_attribute_name
      raise NotImplementedError
    end

    def extract_cpu_cores(param)
      raise NotImplementedError
    end

    def extract_memory_mb(param)
      raise NotImplementedError
    end

    def extract_disk_gb(param)
      raise NotImplementedError
    end

    private

    def load_hosts_eagerly(missing_hosts_resources, host_objects, eager_attribute)
      relevant_hosts = Host::Managed.where(name: missing_hosts_resources.keys).includes(eager_attribute)
      relevant_hosts = relevant_hosts.compact
      if relevant_hosts.size < missing_hosts_resources.size # Add non-eagerly loaded host objects
        relevant_hosts_names = relevant_hosts.map(&:name)
        (missing_hosts_resources.keys - relevant_hosts_names).each do |missing_host_name|
          relevant_hosts << host_objects[missing_host_name]
        end
      end
      relevant_hosts
    rescue ActiveRecord::AssociationNotFoundError
      # the eager_attribute could not be loaded
      host_objects.values
    end

    def collect_attribute_from_hosts(host_list, attribute_name)
      host_values = {}
      host_list.each do |host|
        attribute_value = host.send(attribute_name)
        host_values[host.name] = attribute_value if attribute_value.present?
      rescue StandardError
        # skip hosts whose attribute couldn't be collected. They will be kept in the list
        # of missing host resources
      end
      host_values
    end

    def process_resources_and_delete_missing_hosts!(hosts_resources, missing_hosts_resources, host_values)
      host_values.each do |host_name, attribute_content|
        missing_hosts_resources[host_name].reverse_each do |resource_name|
          resource_value = process_resource(resource_name, attribute_content)
          next unless resource_value
          hosts_resources[host_name][resource_name] = resource_value
          missing_hosts_resources[host_name].delete(resource_name)
        end
        missing_hosts_resources.delete(host_name) if missing_hosts_resources[host_name].empty?
      end
    end

    def process_resource(resource_name, attribute_content)
      resource_value = method(RESOURCE_FUNCTION_MAP[resource_name]).call(attribute_content)
      return nil unless resource_value
      resource_value
    end

    # Extract encapsulated volumes attributes
    #   The structure of data encapslated in :volumes_attributes is inconsistent. For example,
    #   in an API call for host creation call this is an Array. But, through the UI this becomes a Hash.
    # Parameters: A Hash containing :volumes_attributes.
    # Returns: An Array of volume data (expecting an Array of Hashes)
    def extract_volumes(param)
      volumes = param[:volumes_attributes]
      volumes = volumes.values if volumes.is_a?(Hash) # If it's a Hash, extract values
      volumes
    end
  end
end
