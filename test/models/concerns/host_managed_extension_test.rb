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
        Host.any_instance.expects(:verify_resource_quota_on_create).once
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

      def validation_error_message_host(resource, exceeding, max)
        /Validation failed: Resource quota Host exceeds #{resource} limit of \
'[\w\s]+'-quota by #{exceeding} \(max\. #{max}\)/
      end

      def validation_error_message_quota(resource, exceeding, max)
        /Validation failed: Resource quota #{resource} limit of '[\w\s]+'-quota is \
already exceeded by #{exceeding} without adding the new host \(max\. #{max}\)/
      end

      test 'should fail at determine utilization' do
        stub_quota_utilization({}, { 'my.missing.host': [:cpu_cores] }) # fail on quota utilization
        stub_host_utilization({ cpu_cores: 5 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, cpu_cores: 10)
        error = assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:host, resource_quota: quota) }

        assert_match(/Resource quota Resource Quota '[\w\s]+' cannot determine resources for 1 hosts./, error.message)
      end

      test 'should fail at determine host resources' do
        stub_quota_utilization({ cpu_cores: 5 }, {}) # pass quota utilization
        stub_host_utilization({}, { 'my.missing.host': [:cpu_cores] }) # fail on host utilization

        quota = FactoryBot.create(:resource_quota, cpu_cores: 10)
        error = assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:host, resource_quota: quota) }

        assert_match(/Validation failed: Resource quota Cannot determine host resources for [\w\s]+/, error.message)
      end

      test 'should fail due to new host at verify limits (CPU cores)' do
        stub_quota_utilization({ cpu_cores: 5 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 10 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, cpu_cores: 10)
        error = assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:host, resource_quota: quota) }

        assert_match(validation_error_message_host('CPU cores', '5 cores', '10 cores'), error.message)
      end

      test 'should fail due to new host at verify limits (disk space)' do
        stub_quota_utilization({ disk_gb: 5 }, {}) # pass quota utilization
        stub_host_utilization({ disk_gb: 10 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, disk_gb: 10)
        error = assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:host, resource_quota: quota) }

        assert_match(validation_error_message_host('Disk space', '5 GB', '10 GB'), error.message)
      end

      test 'should fail due to new host at verify limits (memory)' do
        stub_quota_utilization({ memory_mb: 5 * 1024 }, {}) # pass quota utilization
        stub_host_utilization({ memory_mb: 10 * 1024 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, memory_mb: 10 * 1024)
        error = assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:host, resource_quota: quota) }

        assert_match(validation_error_message_host('Memory', '5 GB', '10 GB'), error.message)
      end

      test 'should fail due to quota utilization at verify limits (CPU cores)' do
        stub_quota_utilization({ cpu_cores: 10 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 5 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, cpu_cores: 5)
        error = assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:host, resource_quota: quota) }

        assert_match(validation_error_message_quota('CPU cores', '5 cores', '5 cores'), error.message)
      end

      test 'should fail due to quota utilization at verify limits (disk space)' do
        stub_quota_utilization({ disk_gb: 10 }, {}) # pass quota utilization
        stub_host_utilization({ disk_gb: 5 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, disk_gb: 5)
        error = assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:host, resource_quota: quota) }

        assert_match(validation_error_message_quota('Disk space', '5 GB', '5 GB'), error.message)
      end

      test 'should fail due to quota utilization at verify limits (memory)' do
        stub_quota_utilization({ memory_mb: 10 * 1024 }, {}) # pass quota utilization
        stub_host_utilization({ memory_mb: 5 * 1024 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, memory_mb: 5 * 1024)
        error = assert_raises(ActiveRecord::RecordInvalid) { FactoryBot.create(:host, resource_quota: quota) }

        assert_match(validation_error_message_quota('Memory', '5 GB', '5 GB'), error.message)
      end

      test 'should validate single host capacity' do
        stub_quota_utilization({ memory_mb: 0 }, {}) # pass quota utilization
        stub_host_utilization({ memory_mb: 10 * 1024 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, memory_mb: 20 * 1024)
        host = FactoryBot.create(:host, resource_quota: quota)

        assert host.save
        assert_equal({ memory_mb: 10 * 1024 }, quota.utilization)
      end

      test 'should validate multi limit capacity (host only)' do
        stub_quota_utilization({ cpu_cores: 0, memory_mb: 0, disk_gb: 0 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 5, memory_mb: 10 * 1024, disk_gb: 0 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, cpu_cores: 20, memory_mb: 20 * 1024, disk_gb: 50)
        host = FactoryBot.create(:host, resource_quota: quota)

        assert host.save
        assert_equal({ cpu_cores: 5, memory_mb: 10 * 1024, disk_gb: 0 }, quota.utilization)
      end

      test 'should validate multi limit capacity (with quota utilization)' do
        stub_quota_utilization({ cpu_cores: 5, memory_mb: 5 * 1024, disk_gb: 10 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 2, memory_mb: 4 * 1024, disk_gb: 20 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, cpu_cores: 20, memory_mb: 20 * 1024, disk_gb: 50)
        host = FactoryBot.create(:host, resource_quota: quota)

        assert host.save
        assert_equal({ cpu_cores: 7, memory_mb: 9 * 1024, disk_gb: 30 }, quota.utilization)
      end

      test 'should add host capacity only once to quota utilization' do
        stub_quota_utilization({ cpu_cores: 5, memory_mb: 5 * 1024, disk_gb: 10 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 2, memory_mb: 4 * 1024, disk_gb: 20 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, cpu_cores: 20, memory_mb: 20 * 1024, disk_gb: 50)
        host = FactoryBot.create(:host, resource_quota: quota)

        assert host.save
        assert_equal({ cpu_cores: 7, memory_mb: 9 * 1024, disk_gb: 30 }, quota.utilization)
      end

      test 'should remove host capacity from quota utilization' do
        stub_quota_utilization({ cpu_cores: 5, memory_mb: 5 * 1024, disk_gb: 10 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 2, memory_mb: 4 * 1024, disk_gb: 20 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, cpu_cores: 20, memory_mb: 20 * 1024, disk_gb: 50)
        host = FactoryBot.create(:host, resource_quota: quota)

        assert host.save
        assert_equal({ cpu_cores: 7, memory_mb: 9 * 1024, disk_gb: 30 }, quota.utilization)

        host.destroy!
        assert_equal({ cpu_cores: 5, memory_mb: 5 * 1024, disk_gb: 10 }, quota.utilization)
      end

      test 'should add host capacity of two hosts to quota utilization' do
        stub_quota_utilization({ cpu_cores: 5, memory_mb: 5 * 1024, disk_gb: 10 }, {}) # pass quota utilization
        stub_host_utilization({ cpu_cores: 2, memory_mb: 4 * 1024, disk_gb: 20 }, {}) # pass host utilization

        quota = FactoryBot.create(:resource_quota, cpu_cores: 20, memory_mb: 20 * 1024, disk_gb: 50)
        host_a = FactoryBot.create(:host, resource_quota: quota)
        host_b = FactoryBot.create(:host, resource_quota: quota)

        assert host_a.save
        assert host_b.save
        assert_equal({ cpu_cores: 9, memory_mb: 13 * 1024, disk_gb: 50 }, quota.utilization)

        host_a.destroy!
        assert_equal({ cpu_cores: 7, memory_mb: 9 * 1024, disk_gb: 30 }, quota.utilization)
      end

      test 'should re-associate host capacity when changing resource quota' do
        stub_host_utilization({ cpu_cores: 2, memory_mb: 4 * 1024, disk_gb: 20 }, {}) # pass host utilization

        quota_a = FactoryBot.create(:resource_quota,
          cpu_cores: 20,
          memory_mb: 20 * 1024,
          disk_gb: 50)
        quota_b = FactoryBot.create(:resource_quota,
          cpu_cores: 20,
          memory_mb: 20 * 1024,
          disk_gb: 50)
        host = FactoryBot.create(:host, resource_quota: quota_a)

        assert_equal({ cpu_cores: 2, memory_mb: 4 * 1024, disk_gb: 20 }, quota_a.utilization)
        assert_equal({ cpu_cores: nil, memory_mb: nil, disk_gb: nil }, quota_b.utilization)

        host.resource_quota = quota_b
        host.save
        quota_a.reload
        quota_b.reload

        assert_equal({ cpu_cores: 0, memory_mb: 0, disk_gb: 0 }, quota_a.utilization)
        assert_equal({ cpu_cores: 2, memory_mb: 4 * 1024, disk_gb: 20 }, quota_b.utilization)
      end
    end
  end
end
