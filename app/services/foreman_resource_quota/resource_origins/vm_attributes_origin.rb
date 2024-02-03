# frozen_string_literal: true

module ForemanResourceQuota
  module ResourceOrigins
    class VMAttributesOrigin < ResourceOrigin
      def host_attribute_eager_name
        :compute_resource
      end

      def host_attribute_name
        :vm_compute_attributes
      end

      def extract_cpu_cores(param)
        return nil unless param.key?(:cpus)
        param[:cpus]
      rescue StandardError
        nil
      end

      def extract_memory_mb(param)
        return nil unless param.key?(:memory_mb)
        param[:memory_mb]
      rescue StandardError
        nil
      end

      def extract_disk_gb(param)
        return nil unless param.key?(:volumes_attributes)
        extract_volumes(param).sum do |disk|
          # key can be capactiy or size_gb
          return nil unless disk.key?(:capacity) || disk.key?(:size_gb)
          (disk[:size_gb] || disk[:capacity]).to_i
        end
      rescue StandardError
        nil
      end
    end
  end
end
