# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  module Concerns
    module Api
      module V2
        class HostsControllerExtensionsTest < ActionController::TestCase
          tests ::Api::V2::HostsController

          def setup
            User.current = User.find_by login: 'admin'
            @unassigned = ForemanResourceQuota::ResourceQuota.where(
              name: 'Unassigned',
              unassigned: true,
              description: 'Here, you can see all hosts without a dedicated quota.'
            ).first_or_create
            as_admin { @unassigned.save! }
            Setting[:resource_quota_optional_assignment] = false
          end

          test 'should create host with unassigned (default) quota' do
            Setting[:resource_quota_optional_assignment] = true
            host_params = FactoryBot.attributes_for(:host, managed: false)
            post :create, params: { host: host_params }
            assert_response :created
            assert_equal @unassigned.id, JSON.parse(response.body)['resource_quota_id'].to_i
          end

          test 'should fail to create host without assigned quota' do
            host_params = FactoryBot.attributes_for(:host, managed: false)
            post :create, params: { host: host_params }
            assert_response :unprocessable_entity
            assert_match(/No valid resource quota provided/, JSON.parse(response.body)['error']['message'])
            # still fails even when adding a second quota
            quota = FactoryBot.create :resource_quota
            as_admin { quota.save! }
            post :create, params: { host: host_params }
            assert_response :unprocessable_entity
            assert_match(/No valid resource quota provided/, JSON.parse(response.body)['error']['message'])
          end

          test 'should fail to update host without assigned quota' do
            Setting[:resource_quota_optional_assignment] = true
            # create a host without a quota
            as_admin do
              host = FactoryBot.create(:host, owner: User.current, managed: false)
              Setting[:resource_quota_optional_assignment] = false
              put :update, params: { id: host.id, host: { name: host.name } }
            end
            assert_response :unprocessable_entity
            assert_match(/No valid resource quota provided/, JSON.parse(response.body)['error']['message'])
          end

          test 'should update host with valied quota' do
            Setting[:resource_quota_optional_assignment] = true
            # create a host without a quota
            as_admin do
              quota = FactoryBot.create(:resource_quota)
              host = FactoryBot.create(:host, owner: User.current, managed: false)
              Setting[:resource_quota_optional_assignment] = false
              put :update, params: { id: host.id, host: { name: host.name, resource_quota_id: quota.id } }
            end
            assert_response :success
          end

          test 'should succeed to create host with assigned quota' do
            @quota = FactoryBot.create :resource_quota
            as_admin { @quota.save! }
            host_params = FactoryBot.attributes_for(:host, managed: false).merge(resource_quota_id: @quota.id)
            post :create, params: { host: host_params }
            assert_response :created
            assert_equal @quota.id, JSON.parse(response.body)['resource_quota_id'].to_i
          end
        end
      end
    end
  end
end
