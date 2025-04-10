# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class ResourceQuotaTest < ActiveSupport::TestCase
    include Exceptions
    context 'optional quota assignment at host creation' do
      def setup
        Setting[:resource_quota_optional_assignment] = true

        @unassigned = ForemanResourceQuota::ResourceQuota.where(
          name: 'Unassigned',
          unassigned: true,
          description: 'Here, you can see all hosts without a dedicated quota.'
        ).first_or_create
        as_admin { @unassigned.save! }
        @quota = FactoryBot.create :resource_quota
        as_admin { @quota.save! }
        @user = FactoryBot.create :user
        @usergroup = FactoryBot.create :usergroup
        @host = FactoryBot.create :host, resource_quota: @quota
      end

      test 'unassigned quota available' do
        assert_equal ResourceQuota.unassigned, @unassigned
        assert_not_equal ResourceQuota.unassigned, @quota
      end

      test 'cannot delete unassigned quota' do
        assert_raises UnassignedQuotaDeletionException do
          @unassigned.destroy
        end
      end

      test 'assignable quota scope' do
        assert_includes ResourceQuota.assignable, @quota
        assert_not_includes ResourceQuota.assignable, @unassigned
      end

      test 'hosts relation' do
        assert_equal @host.id, @quota.hosts[0].id
        assert_equal @quota.id, @host.reload.resource_quota.id
      end

      test 'host quota is set to unassigned on quota deletion' do
        @quota.destroy
        assert_equal @host.reload.resource_quota, @unassigned
      end

      test 'users relation' do
        @quota.users << @user
        assert_equal @user.id, @quota.users[0].id
        assert_includes @user.resource_quotas, @unassigned
        assert_includes @user.resource_quotas, @quota
      end

      test 'users relation delete user' do
        @quota.users << @user
        assert_equal @user.id, @quota.users[0].id
        assert_includes @user.resource_quotas, @unassigned
        assert_includes @user.resource_quotas, @quota
        @user.destroy
        assert_empty @quota.reload.users
      end

      test 'users relation delete quota' do
        @user.resource_quotas << @quota
        assert_equal @quota.users[0].id, @user.id
        assert_includes @user.resource_quotas, @unassigned
        assert_includes @user.resource_quotas, @quota
        @quota.destroy
        assert_not_includes @user.reload.resource_quotas, @quota
      end

      test 'usergroups relation' do
        @quota.usergroups << @usergroup
        assert_equal @usergroup.id, @quota.usergroups[0].id
        assert_includes @usergroup.resource_quotas, @unassigned
        assert_includes @usergroup.resource_quotas, @quota
      end

      test 'usergroup delete' do
        @quota.usergroups << @usergroup
        assert_equal @usergroup.id, @quota.usergroups[0].id
        assert_includes @usergroup.resource_quotas, @quota
        @usergroup.destroy
        assert_empty @quota.reload.usergroups
      end

      test 'number of hosts' do
        second_host = FactoryBot.create :host, resource_quota: @quota
        third_host = FactoryBot.create :host, resource_quota: @quota
        assert_equal 3, @quota.number_of_hosts
        assert_includes @quota.hosts, @host
        assert_includes @quota.hosts, second_host
        assert_includes @quota.hosts, third_host
      end

      test 'number of users' do
        second_user = FactoryBot.create :user
        third_user = FactoryBot.create :user
        @quota.users << [@user, second_user, third_user]
        assert_equal 3, @quota.number_of_users
      end

      test 'number of usergroups' do
        second_usergroup = FactoryBot.create :usergroup
        third_usergroup = FactoryBot.create :usergroup
        @quota.usergroups << [@usergroup, second_usergroup, third_usergroup]
        assert_equal 3, @quota.number_of_usergroups
      end

      test 'utilization is empty' do
        @quota.cpu_cores = 50
        exp_utilization = { cpu_cores: 0, memory_mb: nil, disk_gb: nil }

        assert_equal exp_utilization, @quota.utilization
      end

      test 'utilization is nil' do
        exp_utilization = { cpu_cores: nil, memory_mb: nil, disk_gb: nil }

        assert_equal exp_utilization, @quota.utilization
      end

      test 'utilization is set (cpu_cores)' do
        @quota.cpu_cores = 50
        @quota.update_hosts_resources({ @host.name => { cpu_cores: 13 } })

        assert_equal 13, @quota.utilization[:cpu_cores]
      end

      test 'utilization is set (memory_mb)' do
        @quota.memory_mb = 50
        @quota.update_hosts_resources({ @host.name => { memory_mb: 14 } })

        assert_equal 14, @quota.utilization[:memory_mb]
      end

      test 'utilization is set (disk_gb)' do
        @quota.disk_gb = 50
        @quota.update_hosts_resources({ @host.name => { disk_gb: 15 } })

        assert_equal 15, @quota.utilization[:disk_gb]
      end

      test 'utilization is set (all parameters)' do
        exp_utilization = { cpu_cores: 3, memory_mb: 4, disk_gb: 5 }
        @quota.update(cpu_cores: 50, memory_mb: 50, disk_gb: 50)
        @quota.update_hosts_resources({ @host.name => exp_utilization })

        assert_equal exp_utilization, @quota.utilization
      end

      test 'determine utilization' do
        exp_utilization = { cpu_cores: 1, memory_mb: 1, disk_gb: 2 }
        exp_missing_hosts = {}
        host_utilization = {
          @host.name => exp_utilization,
        }
        @quota.update(cpu_cores: 10, memory_mb: 10, disk_gb: 10)

        @quota.stub(:call_utilization_helper, [host_utilization, exp_missing_hosts]) do
          @quota.determine_utilization
        end
        assert_equal exp_utilization, @quota.utilization
        assert_equal exp_missing_hosts, @quota.missing_hosts
      end

      test 'determine utilization stores missing hosts' do
        # remove default host from quota
        @host.resource_quota = @unassigned
        host_a = FactoryBot.create :host, resource_quota: @quota
        host_b = FactoryBot.create :host, resource_quota: @quota

        exp_utilization = { cpu_cores: 1, memory_mb: 1, disk_gb: 2 }
        host_utilization = {
          host_a.name => { memory_mb: 1, disk_gb: 1 },
          host_b.name => { cpu_cores: 1, disk_gb: 1 },
        }
        exp_missing_hosts = { host_a.name => [:cpu_cores], host_b.name => [:memory_mb] }

        @quota.update(cpu_cores: 10, memory_mb: 10, disk_gb: 10)

        @quota.stub(:call_utilization_helper, [host_utilization, exp_missing_hosts]) do
          @quota.determine_utilization
        end
        assert_equal exp_utilization, @quota.utilization
        assert_equal exp_missing_hosts, @quota.missing_hosts
      end

      test 'missing_hosts are destroyed on host destroy' do
        # remove default host from quota
        @host.resource_quota = @unassigned
        host_a = FactoryBot.create :host, resource_quota: @quota
        host_b = FactoryBot.create :host, resource_quota: @quota
        host_utilization = {
          host_a.name => { memory_mb: 1, disk_gb: 1 },
          host_b.name => { cpu_cores: 1, disk_gb: 1 },
        }
        exp_missing_hosts = { host_a.name => [:cpu_cores], host_b.name => [:memory_mb] }
        @quota.update(cpu_cores: 10, memory_mb: 10, disk_gb: 10)
        @quota.save!

        @quota.stub(:call_utilization_helper, [host_utilization, exp_missing_hosts]) do
          @quota.determine_utilization
        end
        assert_equal @quota.number_of_missing_hosts, @quota.number_of_hosts
        host_a.destroy
        assert_equal 1, @quota.number_of_missing_hosts
        assert_equal host_b.name, @quota.missing_hosts.keys.first
        host_b.destroy
        assert_equal 0, @quota.number_of_missing_hosts
      end

      test 'missing_hosts are destroyed on re-computing utilization' do
        # remove default host from quota
        @host.resource_quota = @unassigned
        @quota.update(cpu_cores: 10, memory_mb: 10)
        host_a = FactoryBot.create :host, resource_quota: @quota
        host_b = FactoryBot.create :host, resource_quota: @quota
        host_utilization_two = {
          host_a.name => { cpu_cores: 1, memory_mb: nil },
          host_b.name => { cpu_cores: nil, memory_mb: 1 },
        }
        host_utilization_one = {
          host_a.name => { cpu_cores: 1, memory_mb: 1 },
          host_b.name => { cpu_cores: nil, memory_mb: 1 },
        }
        exp_missing_hosts_two = { host_a.name => [:memory_mb], host_b.name => [:cpu_cores] }
        exp_missing_hosts_one = { host_b.name => [:cpu_cores] }

        @quota.stub(:call_utilization_helper, [host_utilization_two, exp_missing_hosts_two]) do
          @quota.determine_utilization
        end
        assert_equal 2, @quota.number_of_missing_hosts
        @quota.stub(:call_utilization_helper, [host_utilization_one, exp_missing_hosts_one]) do
          @quota.determine_utilization
        end
        @quota.reload
        assert_equal 1, @quota.number_of_missing_hosts
        assert_equal [host_b.name], @quota.missing_hosts.keys
      end
    end
  end
end
