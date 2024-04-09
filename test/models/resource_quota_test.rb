# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class ResourceQuotaTest < ActiveSupport::TestCase
    context 'optional quota assignment at host creation' do
      def setup
        Setting[:resource_quota_optional_assignment] = true

        @quota = FactoryBot.create :resource_quota
        @user = FactoryBot.create :user
        @usergroup = FactoryBot.create :usergroup
        @host = FactoryBot.create :host
      end

      test 'hosts relation' do
        @quota.hosts << @host
        as_admin { @quota.save! }
        assert_equal @host.id, @quota.hosts[0].id
        assert_equal @quota.id, @host.resource_quota.id
      end

      test 'users relation' do
        @quota.users << @user
        as_admin { @quota.save! }
        assert_equal @user.id, @quota.users[0].id
        assert_equal @quota.id, @user.resource_quotas[0].id
      end

      test 'users relation delete user' do
        @quota.users << @user
        as_admin { @quota.save! }
        assert_equal @user.id, @quota.users[0].id
        assert_equal @quota.id, @user.resource_quotas[0].id
        as_admin { @user.destroy! }
        assert_empty @quota.reload.users
      end

      test 'users relation delete quota' do
        @user.resource_quotas << @quota
        as_admin { @user.save! }
        assert_equal @quota.users[0].id, @user.id
        assert_equal @user.resource_quotas[0].id, @quota.id
        as_admin { @quota.destroy! }
        assert_empty @user.reload.resource_quotas
      end

      test 'usergroups relation' do
        @quota.usergroups << @usergroup
        as_admin { @quota.save! }
        assert_equal @usergroup.id, @quota.usergroups[0].id
        assert_equal @quota.id, @usergroup.resource_quotas[0].id
      end

      test 'usergroup delete' do
        @quota.usergroups << @usergroup
        as_admin { @quota.save! }
        assert_equal @usergroup.id, @quota.usergroups[0].id
        assert_equal @quota.id, @usergroup.resource_quotas[0].id
        as_admin { @usergroup.destroy! }
        assert_empty @quota.reload.usergroups
      end

      test 'number of hosts' do
        second_host = FactoryBot.create :host
        third_host = FactoryBot.create :host
        @quota.hosts << [@host, second_host, third_host]
        assert_equal 3, @quota.number_of_hosts
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

      test 'utilization is set (cpu_cores)' do
        @quota.utilization_cpu_cores = 13
        assert_equal 13, @quota.utilization[:cpu_cores]
      end

      test 'utilization is set (memory_mb)' do
        @quota.utilization_memory_mb = 14
        assert_equal 14, @quota.utilization[:memory_mb]
      end

      test 'utilization is set (disk_gb)' do
        @quota.utilization_disk_gb = 15
        assert_equal 15, @quota.utilization[:disk_gb]
      end

      test 'utilization is set (all parameters)' do
        exp_utilization = { cpu_cores: 3, memory_mb: 4, disk_gb: 5 }
        @quota.utilization_cpu_cores = exp_utilization[:cpu_cores]
        @quota.utilization_memory_mb = exp_utilization[:memory_mb]
        @quota.utilization_disk_gb = exp_utilization[:disk_gb]
        assert_equal exp_utilization, @quota.utilization
      end

      test 'utilization_<resource> is set by utilization' do
        exp_utilization = { cpu_cores: 6, memory_mb: 7, disk_gb: 8 }
        @quota.utilization = exp_utilization
        assert_equal exp_utilization, @quota.utilization
      end

      test 'utilization sets attributes' do
        second_usergroup = FactoryBot.create :usergroup
        third_usergroup = FactoryBot.create :usergroup
        @quota.usergroups << [@usergroup, second_usergroup, third_usergroup]
        assert_equal 3, @quota.number_of_usergroups
      end

      test 'determine utilization' do
        exp_utilization = { cpu_cores: 1, memory_mb: 1, disk_gb: 2 }
        exp_missing_hosts = {}
        @quota.hosts << @host
        @quota.update(cpu_cores: 10, memory_mb: 10, disk_gb: 10)
        as_admin { @quota.save! }

        @quota.stub(:call_utilization_helper, [exp_utilization, exp_missing_hosts]) do
          @quota.determine_utilization
        end
        assert_equal exp_utilization, @quota.utilization
        assert_equal exp_missing_hosts, @quota.missing_hosts
      end

      test 'determine utilization stores missing hosts' do
        host_a = FactoryBot.create :host
        host_b = FactoryBot.create :host
        exp_utilization = { cpu_cores: 1, memory_mb: 1, disk_gb: 2 }
        exp_missing_hosts = { host_a.name => [:cpu_cores], host_b.name => [:memory_mb] }
        @quota.hosts << [host_a, host_b]
        @quota.update(cpu_cores: 10, memory_mb: 10, disk_gb: 10)
        as_admin { @quota.save! }

        @quota.stub(:call_utilization_helper, [exp_utilization, exp_missing_hosts]) do
          @quota.determine_utilization
        end
        assert_equal exp_utilization, @quota.utilization
        assert_equal exp_missing_hosts, @quota.missing_hosts
      end

      test 'utilization uses quota utilization_ fields' do
        exp_utilization = { cpu_cores: 1, memory_mb: 1, disk_gb: 2 }
        @quota.utilization_cpu_cores = exp_utilization[:cpu_cores]
        @quota.utilization_memory_mb = exp_utilization[:memory_mb]
        @quota.utilization_disk_gb = exp_utilization[:disk_gb]

        assert_equal exp_utilization, @quota.utilization
      end

      test 'missing_hosts are constructed' do
        host_a = FactoryBot.create :host
        host_b = FactoryBot.create :host
        exp_utilization = { cpu_cores: 1, memory_mb: 1, disk_gb: 2 }
        exp_missing_hosts = { host_a.name => [:cpu_cores], host_b.name => [:memory_mb] }
        @quota.hosts << [host_a, host_b]
        @quota.update(cpu_cores: 10, memory_mb: 10, disk_gb: 10)
        as_admin { @quota.save! }

        @quota.stub(:call_utilization_helper, [exp_utilization, exp_missing_hosts]) do
          @quota.determine_utilization
        end
        @quota.reload
        assert_equal exp_missing_hosts, @quota.missing_hosts
        assert_equal 2, @quota.resource_quotas_missing_hosts.size
        assert_equal host_a.id, @quota.resource_quotas_missing_hosts.find_by(missing_host_id: host_a.id).missing_host_id
        assert_equal host_b.id, @quota.resource_quotas_missing_hosts.find_by(missing_host_id: host_b.id).missing_host_id
        assert_equal host_a.resource_quota_missing_resources.resource_quota.id, @quota.id
      end

      test 'missing_hosts are destroyed on host destroy' do
        host_a = FactoryBot.create :host
        host_b = FactoryBot.create :host
        exp_utilization = { cpu_cores: 1, memory_mb: 1, disk_gb: 2 }
        exp_missing_hosts = { host_a.name => [:cpu_cores], host_b.name => [:memory_mb] }
        @quota.hosts << [host_a, host_b]
        @quota.update(cpu_cores: 10, memory_mb: 10, disk_gb: 10)
        as_admin { @quota.save! }

        @quota.stub(:call_utilization_helper, [exp_utilization, exp_missing_hosts]) do
          @quota.determine_utilization
        end
        assert_equal 2, @quota.resource_quotas_missing_hosts.size
        host_a.destroy!
        @quota.reload
        assert_equal 1, @quota.resource_quotas_missing_hosts.size
        assert_equal host_b.id, @quota.resource_quotas_missing_hosts[0].missing_host.id
        host_b.destroy!
        @quota.reload
        assert_equal 0, @quota.resource_quotas_missing_hosts.size
      end

      test 'missing_hosts are destroyed on re-computing utilization' do
        host_a = FactoryBot.create :host
        host_b = FactoryBot.create :host
        exp_utilization = { cpu_cores: 1, memory_mb: 1, disk_gb: 2 }
        exp_missing_hosts_two = { host_a.name => [:cpu_cores], host_b.name => [:memory_mb] }
        exp_missing_hosts_one = { host_b.name => [:memory_mb] }
        @quota.hosts << [host_a, host_b]
        @quota.update(cpu_cores: 10, memory_mb: 10, disk_gb: 10)
        as_admin { @quota.save! }

        @quota.stub(:call_utilization_helper, [exp_utilization, exp_missing_hosts_two]) do
          @quota.determine_utilization
        end
        assert_equal 2, @quota.resource_quotas_missing_hosts.size
        @quota.stub(:call_utilization_helper, [exp_utilization, exp_missing_hosts_one]) do
          @quota.determine_utilization
        end
        @quota.reload
        assert_equal 1, @quota.resource_quotas_missing_hosts.size
        assert_equal host_b.id, @quota.resource_quotas_missing_hosts
                                      .find_by(missing_host_id: host_b.id).missing_host_id
      end
    end
  end
end
