# frozen_string_literal: true

module ForemanResourceQuota
  module ResourceOrigin
    class VMAttributesOrigin < ResourceOrigin
      def host_eager_name
        :compute_resource
      end

      def host_attribute_name
        :vm_compute_attributes
      end

      def extract_cpu_cores(param)
        param[:cpus]
      rescue StandardError
        nil
      end

      def extract_memory_mb(param)
        param[:memory_mb]
      rescue StandardError
        nil
      end

      def extract_disk_gb(param)
        param[:volumes_attributes].values.sum { |disk| disk[:size_gb].to_i }
      rescue StandardError
        nil
      end
    end
  end
end
