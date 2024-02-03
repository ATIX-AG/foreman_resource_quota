# frozen_string_literal: true

module ForemanResourceQuota
  module ResourceOrigins
    class ComputeAttributesOrigin < ResourceOrigin
      def host_attribute_eager_name
        :compute_attributes
      end

      def host_attribute_name
        :compute_attributes
      end

      def extract_cpu_cores(param)
        return nil unless param.key?(:cpus)
        param[:cpus].to_i
      rescue StandardError
        nil
      end

      def extract_memory_mb(param)
        case determine_memory_key(param)
        when :memory
          param[:memory].to_i / ResourceQuotaHelper::FACTOR_B_TO_MB
        when :memory_mb
          param[:memory_mb].to_i
        end
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

      private

      def determine_memory_key(param)
        return :memory if param.key?(:memory)
        return :memory_mb if param.key?(:memory_mb)
        nil
      end

      def parse_storage_string(storage_str)
        return nil unless storage_str.is_a? String
        case storage_str[-1].upcase
        when 'G'
          storage_str.to_i
        when 'T'
          storage_str[0..-2].to_i * ResourceQuotaHelper::FACTOR_B_TO_MB
        when 'M'
          (storage_str[0..-2].to_f / ResourceQuotaHelper::FACTOR_B_TO_MB).ceil
        end
      end
    end
  end
end
