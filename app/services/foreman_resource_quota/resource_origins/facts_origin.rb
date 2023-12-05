# frozen_string_literal: true

module ForemanResourceQuota
  module ResourceOrigin
    class FactsOrigin < ResourceOrigin
      FACTS_KEYS_CPU_CORES = [
        'ansible_processor_cores',
        'facter_processors::cores',
        'proc_cpuinfo::common::cpu_cores',
        'processors::cores',
      ].freeze

      FACTS_KEYS_MEMORY_B = [
        'facter_memory::system::total_bytes',
        'memory::system::total_bytes',
        'memory::memtotal',
      ].freeze

      FACTS_REGEX_DISK_B = [
        /^disks::(\w+)::size_bytes$/,
        /^facter_disks::(\w+)::size_bytes$/,
      ].freeze

      def host_eager_name
        :fact_values
      end

      def host_attribute_name
        :facts
      end

      def extract_cpu_cores(param)
        common_keys = param.keys & FACTS_KEYS_CPU_CORES
        return param[common_keys.first].to_i if common_keys.any?
        nil
      rescue StandardError
        nil
      end

      def extract_memory_mb(param)
        common_keys = param.keys & FACTS_KEYS_MEMORY_B
        return (param[common_keys.first].to_i / FACTOR_B_TO_MB).to_i if common_keys.any?
        nil
      rescue StandardError
        nil
      end

      def extract_disk_gb(param)
        total_gb = nil

        FACTS_REGEX_DISK_B.each do |regex|
          relevant_keys = param.keys.grep(regex)
          next unless relevant_keys.any?

          total_gb = sum_disk_space(param, relevant_keys)
        end

        total_gb&.to_i
      rescue StandardError
        nil
      end

      def sum_disk_space(facts, keys)
        keys.map { |key| facts[key].to_i }.sum / FACTOR_B_TO_GB unless keys.empty?
      end
    end
  end
end
