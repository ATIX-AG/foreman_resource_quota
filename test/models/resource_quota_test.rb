# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class ResourceQuotaTest < ActiveSupport::TestCase
    def setup
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
    test 'usergroups relation' do
      @quota.usergroups << @usergroup
      as_admin { @quota.save! }
      assert_equal @usergroup.id, @quota.usergroups[0].id
      assert_equal @quota.id, @usergroup.resource_quotas[0].id
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

    test 'determine utilization' do
      exp_utilization = { cpu_cores: 1, memory_mb: 1, disk_gb: 2 }
      exp_missing_hosts = []
      @quota.hosts << @host
      as_admin { @quota.save! }

      @quota.stub(:call_utilization_helper, [exp_utilization, exp_missing_hosts]) do
        @quota.determine_utilization
      end
      assert_equal exp_utilization.transform_keys(&:to_s), @quota.utilization
      assert_equal exp_missing_hosts, @quota.missing_hosts
    end
  end
end
