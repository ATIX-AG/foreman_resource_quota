# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class UserExtensionTest < ActiveSupport::TestCase
    include ForemanResourceQuota::ResourceQuotaHelper

    def setup
      @unassigned = ForemanResourceQuota::ResourceQuota.where(
        name: 'Unassigned',
        unassigned: true,
        description: 'Here, you can see all hosts without a dedicated quota.'
      ).first_or_create
      @quota = FactoryBot.create(:resource_quota)
      as_admin { @quota.save! }
      @user = FactoryBot.create(:user)
    end

    test 'user created with unassigned quota by default' do
      assert_includes @user.resource_quotas, @unassigned
    end

    test 'user has assignable quotas' do
      @user.resource_quotas << @quota
      assert_includes @user.assignable_resource_quotas, @quota
      assert_not_includes @user.assignable_resource_quotas, @unassigned
    end

    test 'always return true when user quota assignement is optional' do
      @user.resource_quota_is_optional = true
      Setting['resource_quota_optional_assignment'] = true
      assert @user.quota_assignment_optional?
      # user setting should overwrite global setting
      Setting['resource_quota_optional_assignment'] = false
      assert @user.quota_assignment_optional?
    end

    test 'Only return false if user quota assignement is not optional' do
      @user.resource_quota_is_optional = false
      # global setting should overwrite user setting if true
      Setting['resource_quota_optional_assignment'] = true
      assert @user.quota_assignment_optional?
      # if all settings are set to false, should return false
      Setting['resource_quota_optional_assignment'] = false
      assert_not @user.quota_assignment_optional?
    end

    test 'show warning if hosts unassigned and assignment not optional' do
      @user.resource_quota_is_optional = false
      Setting['resource_quota_optional_assignment'] = true
      FactoryBot.create(:host, resource_quota: @unassigned, owner: @user)
      Setting['resource_quota_optional_assignment'] = false
      assert @user.show_unassigned_hosts_warning?
    end

    test 'do not show warning if hosts unassigned and assignment optional' do
      @user.resource_quota_is_optional = false
      # global setting should overwrite user setting if true
      Setting['resource_quota_optional_assignment'] = true
      FactoryBot.create(:host, resource_quota: @unassigned, owner: @user)
      assert_not @user.show_unassigned_hosts_warning?
    end
  end
end
