# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class UsergroupExtensionTest < ActiveSupport::TestCase
    include ForemanResourceQuota::ResourceQuotaHelper

    def setup
      @unassigned = ForemanResourceQuota::ResourceQuota.where(
        name: 'Unassigned',
        unassigned: true,
        description: 'Here, you can see all hosts without a dedicated quota.'
      ).first_or_create
      @quota = FactoryBot.create(:resource_quota)
      as_admin { @quota.save! }
      @usergroup = FactoryBot.create(:usergroup)
    end

    test 'usergroup created with unassigned quota by default' do
      assert_includes @usergroup.resource_quotas, @unassigned
    end

    test 'usergroup has assignable quotas' do
      @usergroup.resource_quotas << @quota
      assert_includes @usergroup.assignable_resource_quotas, @quota
      assert_not_includes @usergroup.assignable_resource_quotas, @unassigned
    end

    test 'usergroup quota assignment should correspond to global setting ' do
      Setting['resource_quota_optional_assignment'] = true
      assert @usergroup.quota_assignment_optional?
      Setting['resource_quota_optional_assignment'] = false
      assert_not @usergroup.quota_assignment_optional?
    end
  end
end
