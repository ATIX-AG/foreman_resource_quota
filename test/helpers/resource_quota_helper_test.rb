# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class ResourceQuotaHelperTest < ActiveSupport::TestCase
    include ForemanResourceQuota::ResourceQuotaHelper

    describe 'natural resource by type' do
      test 'CPU type' do
        assert_equal 'CPU cores', natural_resource_name_by_type(:cpu_cores)
      end

      test 'memory type' do
        assert_equal 'Memory', natural_resource_name_by_type(:memory_mb)
      end

      test 'disk space type' do
        assert_equal 'Disk space', natural_resource_name_by_type(:disk_gb)
      end

      test 'raises error for unknown type' do
        assert_raises Exception do
          natural_resource_name_by_type(:disk_space)
        end
      end
    end

    describe 'units by type' do
      test 'CPU type' do
        units = [{ symbol: 'cores', factor: 1 }]
        assert_equal units, units_by_type(:cpu_cores)
      end

      test 'memory type' do
        units = [
          { symbol: 'MB', factor: 1 },
          { symbol: 'GB', factor: FACTOR_B_TO_KB },
          { symbol: 'TB', factor: FACTOR_B_TO_MB },
        ]
        assert_equal units, units_by_type(:memory_mb)
      end

      test 'disk space type' do
        units = [
          { symbol: 'GB', factor: 1 },
          { symbol: 'TB', factor: FACTOR_B_TO_KB },
          { symbol: 'PB', factor: FACTOR_B_TO_MB },
        ]
        assert_equal units, units_by_type(:disk_gb)
      end

      test 'raises error for unknown type' do
        assert_raises Exception do
          units_by_type(:disk_space)
        end
      end
    end

    context 'optional quota assignment at host creation' do
      def setup
        Setting[:resource_quota_optional_assignment] = true
      end

      test 'builds missing resource per host list' do
        hosts = []
        hosts << (FactoryBot.create :host)
        hosts << (FactoryBot.create :host)
        quota_utilization = %i[cpu_cores memory_mb disk_gb]
        missing_host_res = create_missing_hosts_resources_hash(hosts, quota_utilization)
        assert_equal quota_utilization, missing_host_res[hosts[0].name]
        assert_equal quota_utilization, missing_host_res[hosts[1].name]
      end
    end

    describe 'resource to unit string' do
      test 'CPU Cores to resource string' do
        assert_equal '123 cores', resource_value_to_string(123, :cpu_cores)
      end

      test 'CPU Cores to resource string (float)' do
        assert_equal '123.5 cores', resource_value_to_string(123.5, :cpu_cores)
      end

      test 'CPU Cores to resource string (large)' do
        assert_equal '51239 cores', resource_value_to_string(51_239, :cpu_cores)
      end

      test 'memory to resource string' do
        assert_equal '1023 MB', resource_value_to_string(1023, :memory_mb)
      end

      test 'memory to resource string (float)' do
        assert_equal '1023.5 MB', resource_value_to_string(1023.5, :memory_mb)
      end

      test 'memory to resource string (GB)' do
        assert_equal '5 GB', resource_value_to_string((1024 * 5.3).round, :memory_mb)
      end

      test 'memory to resource string (TB)' do
        assert_equal '123 TB', resource_value_to_string(1024 * 1024 * 123, :memory_mb)
      end

      test 'disk space to resource string' do
        assert_equal '5 GB', resource_value_to_string(5, :disk_gb)
      end

      test 'disk space to resource string (float)' do
        assert_equal '5.5 GB', resource_value_to_string(5.5, :disk_gb)
      end

      test 'disk space to resource string (TB)' do
        assert_equal '532 TB', resource_value_to_string(1024 * 532, :disk_gb)
      end

      test 'disk space to resource string (PB)' do
        assert_equal '823 PB', resource_value_to_string(1024 * 1024 * 823, :disk_gb)
      end
    end

    describe 'find largest unit' do
      test 'find largest unit for CPU Cores' do
        (symbol, factor) = find_largest_unit(19, units_by_type(:cpu_cores))
        assert_equal 'cores', symbol
        assert_equal 1, factor
      end

      test 'find largest unit for CPU Cores (large)' do
        (symbol, factor) = find_largest_unit(512_301, units_by_type(:cpu_cores))
        assert_equal 'cores', symbol
        assert_equal 1, factor
      end

      test 'find largest unit for memory MB' do
        (symbol, factor) = find_largest_unit(50, units_by_type(:memory_mb))
        assert_equal 'MB', symbol
        assert_equal 1, factor
      end

      test 'find largest unit for memory MB (large)' do
        (symbol, factor) = find_largest_unit(1023, units_by_type(:memory_mb))
        assert_equal 'MB', symbol
        assert_equal 1, factor
      end

      test 'find largest unit for memory GB' do
        (symbol, factor) = find_largest_unit(1024, units_by_type(:memory_mb))
        assert_equal 'GB', symbol
        assert_equal 1024, factor
      end

      test 'find largest unit for memory GB (mid)' do
        (symbol, factor) = find_largest_unit(39 * 1024, units_by_type(:memory_mb))
        assert_equal 'GB', symbol
        assert_equal 1024, factor
      end

      test 'find largest unit for memory GB (large)' do
        (symbol, factor) = find_largest_unit((1024 * 1024) - 1, units_by_type(:memory_mb))
        assert_equal 'GB', symbol
        assert_equal 1024, factor
      end

      test 'find largest unit for memory TB' do
        (symbol, factor) = find_largest_unit(1024 * 1024, units_by_type(:memory_mb))
        assert_equal 'TB', symbol
        assert_equal 1024 * 1024, factor
      end

      test 'find largest unit for memory TB (mid)' do
        (symbol, factor) = find_largest_unit(1024 * 1024 * 49, units_by_type(:memory_mb))
        assert_equal 'TB', symbol
        assert_equal 1024 * 1024, factor
      end

      test 'find largest unit for memory TB (large)' do
        (symbol, factor) = find_largest_unit(1024 * 1024 * 1026, units_by_type(:memory_mb))
        assert_equal 'TB', symbol
        assert_equal 1024 * 1024, factor
      end

      test 'find largest unit for disk space GB' do
        (symbol, factor) = find_largest_unit(5, units_by_type(:disk_gb))
        assert_equal 'GB', symbol
        assert_equal 1, factor
      end

      test 'find largest unit for disk space GB (large)' do
        (symbol, factor) = find_largest_unit(1023, units_by_type(:disk_gb))
        assert_equal 'GB', symbol
        assert_equal 1, factor
      end

      test 'find largest unit for disk space TB' do
        (symbol, factor) = find_largest_unit(1024, units_by_type(:disk_gb))
        assert_equal 'TB', symbol
        assert_equal 1024, factor
      end

      test 'find largest unit for disk space TB (mid)' do
        (symbol, factor) = find_largest_unit(1024 * 59, units_by_type(:disk_gb))
        assert_equal 'TB', symbol
        assert_equal 1024, factor
      end

      test 'find largest unit for disk space TB (large)' do
        (symbol, factor) = find_largest_unit((1024 * 1024) - 1, units_by_type(:disk_gb))
        assert_equal 'TB', symbol
        assert_equal 1024, factor
      end

      test 'find largest unit for disk space PB' do
        (symbol, factor) = find_largest_unit(1024 * 1024, units_by_type(:disk_gb))
        assert_equal 'PB', symbol
        assert_equal 1024 * 1024, factor
      end

      test 'find largest unit for disk space PB (mid)' do
        (symbol, factor) = find_largest_unit(1024 * 1024 * 98, units_by_type(:disk_gb))
        assert_equal 'PB', symbol
        assert_equal 1024 * 1024, factor
      end

      test 'find largest unit for disk space PB (large)' do
        (symbol, factor) = find_largest_unit(1024 * 1024 * 1025, units_by_type(:disk_gb))
        assert_equal 'PB', symbol
        assert_equal 1024 * 1024, factor
      end
    end
  end
end
