# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class ResourceQuotasControllerTest < ActionController::TestCase
    tests ForemanResourceQuota::ResourceQuotasController

    setup do
      @quota = FactoryBot.create :resource_quota
      User.current = User.find_by login: 'admin'
      as_admin { @quota.save! }
    end

    test 'should get index' do
      get :index, session: set_session_user
      assert_response :success
      assert_select 'title', 'Resource quotas'
    end

    test 'should destroy quota' do
      put :destroy, params: { id: @quota.id }, session: set_session_user
      assert_response :found
    end

    test 'should not find quota to destroy' do
      invalid_id = ResourceQuota.all.map(&:id).sum + 1
      assert_not_nil invalid_id
      put :destroy, params: { id: invalid_id }, session: set_session_user
      assert_response :not_found
    end
  end
end
