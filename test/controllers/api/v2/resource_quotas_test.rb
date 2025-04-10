# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  module Api
    module V2
      class ResourceQuotasControllerTest < ActionController::TestCase
        tests ForemanResourceQuota::Api::V2::ResourceQuotasController
        def setup
          User.current = User.find_by login: 'admin'
          @quota = FactoryBot.create :resource_quota
          @unassigned = ForemanResourceQuota::ResourceQuota.where(
            name: 'Unassigned',
            unassigned: true,
            description: 'Here, you can see all hosts without a dedicated quota.'
          ).first_or_create
          as_admin { @quota.save! }
          as_admin { @unassigned.save! }
        end

        test 'should get index with quotas' do
          get :index, session: set_session_user
          assert_response :success
          index_results = ActiveSupport::JSON.decode(@response.body)['results']
          assert_not_empty index_results
          assert_not_nil assigns(:resource_quotas)
          assert_equal @quota.id, index_results[0]['id']
        end

        test 'should show quota' do
          get :show, params: { id: @quota.id }, session: set_session_user
          assert_response :success
          show_response = ActiveSupport::JSON.decode(@response.body)
          assert_not show_response.empty?
          assert_equal @quota.id, show_response['id']
        end

        test 'should not show invalid quota' do
          invalid_id = ResourceQuota.all.map(&:id).sum + 1
          assert_not_nil invalid_id
          get :show, params: { id: invalid_id }, session: set_session_user
          assert_response :not_found
        end

        test 'should create quota' do
          quota_name = 'testing quota for ForemanResourceQuota::Api:V2:ResourceQuotasController.create'
          quota_cpus = 128
          nof_quota_before = ResourceQuota.all.size

          put :create, params: { name: quota_name, cpu_cores: quota_cpus }, session: set_session_user
          assert_response :success
          created_quota = ResourceQuota.find_by(name: quota_name)
          assert_not_nil created_quota
          assert_quota_equal [quota_name, nil, quota_cpus, nil, nil], created_quota
          assert_equal nof_quota_before + 1, ResourceQuota.all.size
        end

        test 'should create quota with all attributes' do
          quota_name = 'testing quota with attributes for ForemanResourceQuota::Api:V2:ResourceQuotasController.create'
          quota_desc = 'testing non-empty quota description'
          quota_cpus = 128
          quota_memory = 512
          quota_disk = 1024
          nof_quota_before = ResourceQuota.all.size

          put :create, params: { name: quota_name,
                                 description: quota_desc,
                                 cpu_cores: quota_cpus,
                                 memory_mb: quota_memory,
                                 disk_gb: quota_disk }, session: set_session_user
          assert_response :success
          created_quota = ResourceQuota.find_by(name: quota_name)
          assert_not_nil created_quota
          assert_quota_equal [quota_name, quota_desc, quota_cpus, quota_memory, quota_disk], created_quota
          assert_equal nof_quota_before + 1, ResourceQuota.all.size
        end

        test 'should not create quota without name' do
          quota_cpus = 128
          nof_quota_before = ResourceQuota.all.size

          put :create, params: { cpu_cores: quota_cpus }, session: set_session_user
          assert_response :unprocessable_entity
          assert_equal nof_quota_before, ResourceQuota.all.size
        end

        test 'should update quota' do
          @quota.cpu_cores = 128
          as_admin { @quota.save! }
          new_cores = 512

          put :update, params: { id: @quota.id, resource_quota: { cpu_cores: new_cores } }, session: set_session_user
          assert_response :success
          updated_quota = ResourceQuota.find_by(id: @quota.id)
          assert_not_nil updated_quota
          assert_quota_equal [@quota.name,
                              @quota.description,
                              new_cores,
                              @quota.memory_mb,
                              @quota.disk_gb], updated_quota
        end

        test 'should not update quota' do
          second_quota = as_admin { FactoryBot.create :resource_quota }
          as_admin { @quota.save! }

          put :update, params: { id: @quota.id, resource_quota: { name: second_quota.name } }, session: set_session_user
          assert_response :unprocessable_entity
          assert_not_equal @quota.name, second_quota.name
        end

        test 'should destroy quota' do
          nof_quota_before = ResourceQuota.all.size
          put :destroy, params: { id: @quota.id }, session: set_session_user
          assert_response :success
          assert_equal nof_quota_before - 1, ResourceQuota.all.size
        end

        test 'should not destroy any quota' do
          nof_quota_before = ResourceQuota.all.size
          invalid_id = ResourceQuota.all.map(&:id).sum + 1

          assert_not_nil invalid_id
          put :destroy, params: { id: invalid_id }, session: set_session_user
          assert_response :not_found
          assert_equal nof_quota_before, ResourceQuota.all.size
        end

        test 'should show utilization' do
          exp_utilization = { cpu_cores: 10, memory_mb: 20 }
          stub_quota_utilization(exp_utilization)
          get :utilization, params: { resource_quota_id: @quota.id }, session: set_session_user
          assert_response :success
          show_response = ActiveSupport::JSON.decode(@response.body)
          assert_not show_response.empty?
          assert_equal @quota.id, show_response['id']
          assert_equal exp_utilization, show_response['utilization'].transform_keys(&:to_sym)
        end

        test 'should show missing_hosts' do
          exp_missing_hosts = { 'some_host' => %i[cpu_cores memory_mb] }
          stub_quota_missing_hosts(exp_missing_hosts)
          get :missing_hosts, params: { resource_quota_id: @quota.id }, session: set_session_user
          assert_response :success
          show_response = ActiveSupport::JSON.decode(@response.body)
          assert_not show_response.empty?
          assert_equal @quota.id, show_response['id']
          # JSON.decode makes everything strings -> convert 'some_host' value to symbols:
          assert_equal(exp_missing_hosts,
            show_response['missing_hosts'].transform_values { |value| value.map(&:to_sym) })
        end
      end
    end
  end
end
