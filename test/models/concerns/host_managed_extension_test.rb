# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class HostManagedExtensionTest < ActiveSupport::TestCase
    include ForemanResourceQuota::ResourceQuotaHelper

    describe 'host create validation' do
      def setup
        # Set relevant settings explicitly
        Setting[:resource_quota_global_no_action] = false
        Setting[:resource_quota_optional_assignment] = false
        User.current.resource_quota_is_optional = false
      end

      test 'should validate resource quota capacity' do
        Host.any_instance.expects(:check_resource_quota_capacity).once
        FactoryBot.create(:host, :with_resource_quota)
      end

      test 'should succeed with resource quota' do
        assert FactoryBot.create(:host, :with_resource_quota)
      end

      test 'should succeed without resource quota and optional setting (global)' do
        Setting[:resource_quota_optional_assignment] = true
        assert FactoryBot.create(:host)
      end

      test 'should succeed without resource quota and optional setting (user)' do
        User.current.resource_quota_is_optional = true
        assert FactoryBot.create(:host)
      end

      test 'should fail without resource quota' do
        assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:host) }
      end
    end

    describe 'resource quota capacity' do
      def setup
        @host = FactoryBot.create(:host, :with_resource_quota)
        @quota = @host.resource_quota
        Setting[:resource_quota_global_no_action] = false
        Setting[:resource_quota_optional_assignment] = false
        User.current.resource_quota_is_optional = false
      end

      test 'should fail at determine utilization' do
        stub_quota_utilization({}, { 'my.missing.host': [:cpu_cores] }) # fail on quota utilization
        stub_host_utilization({ cpu_cores: 5 }, {}) # pass host utilization
        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(cpu_cores: 10)

        assert_not host.save
        assert_includes host.errors.full_messages, # TODO: Determine why the error fails
          "Resource quota Resource Quota '#{host.resource_quota.name}' cannot determine resources for 1 hosts."
      end

      test 'should fail at determine host resources' do
        stub_quota_utilization({ cpu_cores: 5 }, {}) # pass quota utilization
        stub_host_utilization({}, { 'my.missing.host': [:cpu_cores] }) # fail on host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(cpu_cores: 10)

        assert_not host.save
        assert_includes host.errors.full_messages,
          "Resource quota Cannot determine host resources for #{host.name}"
      end

      test 'should fail due to new host at verify limits (CPU cores)' do
        stub_quota_utilization({ cpu_cores: 5 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 10 }, {}) # pass host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(cpu_cores: 10)

        assert_not host.save
        assert_includes host.errors.full_messages,
          "Resource quota Host exceeds CPU cores limit of '#{host.resource_quota.name}'-quota " \
          'by 5 cores (max. 10 cores)'
      end

      test 'should fail due to new host at verify limits (disk space)' do
        stub_quota_utilization({ disk_gb: 5 }, {}) # pass quota utilization
        stub_host_utilization({ disk_gb: 10 }, {}) # pass host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(disk_gb: 10)

        assert_not host.save
        assert_includes host.errors.full_messages,
          "Resource quota Host exceeds Disk space limit of '#{host.resource_quota.name}'-quota " \
          'by 5 GB (max. 10 GB)'
      end

      test 'should fail due to new host at verify limits (memory)' do
        stub_quota_utilization({ memory_mb: 5 * 1024 }, {}) # pass quota utilization
        stub_host_utilization({ memory_mb: 10 * 1024 }, {}) # pass host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(memory_mb: 10 * 1024)

        assert_not host.save
        assert_includes host.errors.full_messages,
          "Resource quota Host exceeds Memory limit of '#{host.resource_quota.name}'-quota " \
          'by 5 GB (max. 10 GB)'
      end

      test 'should fail due to quota utilization at verify limits (CPU cores)' do
        stub_quota_utilization({ cpu_cores: 15 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 10 }, {}) # pass host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(cpu_cores: 10)

        assert_not host.save
        assert_includes host.errors.full_messages,
          "Resource quota CPU cores limit of '#{host.resource_quota.name}'-quota " \
          'is already exceeded by 5 cores without adding the new host (max. 10 cores)'
      end

      test 'should fail due to quota utilization at verify limits (disk space)' do
        stub_quota_utilization({ disk_gb: 15 }, {}) # pass quota utilization
        stub_host_utilization({ disk_gb: 10 }, {}) # pass host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(disk_gb: 10)

        assert_not host.save
        assert_includes host.errors.full_messages,
          "Resource quota Disk space limit of '#{host.resource_quota.name}'-quota " \
          'is already exceeded by 5 GB without adding the new host (max. 10 GB)'
      end

      test 'should fail due to quota utilization at verify limits (memory)' do
        stub_quota_utilization({ memory_mb: 15 * 1024 }, {}) # pass quota utilization
        stub_host_utilization({ memory_mb: 10 * 1024 }, {}) # pass host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(memory_mb: 10 * 1024)

        assert_not host.save
        assert_includes host.errors.full_messages,
          "Resource quota Memory limit of '#{host.resource_quota.name}'-quota " \
          'is already exceeded by 5 GB without adding the new host (max. 10 GB)'
      end

      test 'should validate single host capacity' do
        stub_quota_utilization({ memory_mb: 0 }, {}) # pass quota utilization
        stub_host_utilization({ memory_mb: 10 * 1024 }, {}) # pass host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(memory_mb: 10 * 1024)

        assert host.save
        # TODO: Test must be adapted, when host resources are added to resource quota
        # assert_equal 10 * 1024, host.resource_quota.utilization[:memory_mb]
        assert_nil host.resource_quota.utilization[:cpu_cores]
        assert_equal 0, host.resource_quota.utilization[:memory_mb]
        assert_nil host.resource_quota.utilization[:disk_gb]
      end

      test 'should validate multi limit capacity (host only)' do
        stub_quota_utilization({ cpu_cores: 0, memory_mb: 0, disk_gb: 0 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 5, memory_mb: 10 * 1024, disk_gb: 0 }, {}) # pass host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(cpu_cores: 20)
        host.resource_quota.update!(memory_mb: 20 * 1024)
        host.resource_quota.update!(disk_gb: 50)

        assert host.save
        # TODO: Test must be adapted, when host resources are added to resource quota
        # assert_equal 5, host.resource_quota.utilization[:cpu_cores]
        # assert_equal 10 * 1024, host.resource_quota.utilization[:memory_mb]
        # assert_equal 0, host.resource_quota.utilization[:disk_gb]
        assert_equal 0, host.resource_quota.utilization[:cpu_cores]
        assert_equal 0, host.resource_quota.utilization[:memory_mb]
        assert_equal 0, host.resource_quota.utilization[:disk_gb]
      end

      test 'should validate multi limit capacity (with quota utilization)' do
        stub_quota_utilization({ cpu_cores: 5, memory_mb: 5 * 1024, disk_gb: 10 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 2, memory_mb: 4 * 1024, disk_gb: 20 }, {}) # pass host utilization

        host = FactoryBot.create(:host, :with_resource_quota)
        host.resource_quota.update!(cpu_cores: 20)
        host.resource_quota.update!(memory_mb: 20 * 1024)
        host.resource_quota.update!(disk_gb: 50)

        assert host.save
        # TODO: Test must be adapted, when host resources are added to resource quota
        # assert_equal 7, host.resource_quota.utilization[:cpu_cores]
        # assert_equal 9 * 1024, host.resource_quota.utilization[:memory_mb]
        # assert_equal 30, host.resource_quota.utilization[:disk_gb]
        assert_equal 5, host.resource_quota.utilization[:cpu_cores]
        assert_equal 5 * 1024, host.resource_quota.utilization[:memory_mb]
        assert_equal 10, host.resource_quota.utilization[:disk_gb]
      end
    end
  end
end
