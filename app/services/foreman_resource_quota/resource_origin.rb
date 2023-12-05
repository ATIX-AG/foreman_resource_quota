# frozen_string_literal: true

module ForemanResourceQuota
  module ResourceOrigin
    class ResourceOrigin
      RESOURCE_FUNCTION_MAP = {
        cpu_cores: :extract_cpu_cores,
        memory_mb: :extract_memory_mb,
        disk_gb: :extract_disk_gb,
      }.freeze

      def collect_resources!(resources_sum, missing_res_per_host)
        return if missing_res_per_host.empty?

        relevant_hosts = Host::Managed.where(id: missing_res_per_host.keys).includes(host_eager_name)
        relevant_hosts = relevant_hosts.compact
        host_values = collect_attribute_from_hosts(relevant_hosts, host_attribute_name)
        host_values.each do |host_id, attribute_content|
          missing_res_per_host[host_id].reverse_each do |resource_name|
            process_resource!(resources_sum, missing_res_per_host, resource_name, host_id,
              attribute_content)
          end
          missing_res_per_host.delete(host_id) if missing_res_per_host[host_id].empty?
        end
      end

      def host_eager_name
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

      def collect_attribute_from_hosts(host_list, attribute_name)
        host_values = []
        host_list.each do |host|
          host_attribute = host.send(attribute_name)
          host_values << [host.id, host_attribute] if host_attribute.present?
        rescue StandardError
          # skip hosts whose attribute couldn't be collected
        end
        host_values
      end

      def process_resource!(resources_sum, missing_res_per_host, resource_name, host_id, attribute_content)
        resource_value = method(RESOURCE_FUNCTION_MAP[resource_name]).call(attribute_content)
        return unless resource_value

        resources_sum[resource_name] += resource_value
        missing_res_per_host[host_id].delete(resource_name)
      end
    end
  end
end
