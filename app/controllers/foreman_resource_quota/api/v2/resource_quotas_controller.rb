# frozen_string_literal: true

module ForemanResourceQuota
  module Api
    module V2
      class ResourceQuotasController < ::Api::V2::BaseController
        include ::Api::Version2
        include Foreman::Controller::Parameters::ResourceQuota

        resource_description do
          resource_id 'resource_quota'
          api_version 'v2'
          api_base_url '/foreman_resource_quota/api'
          # resource quota are not bound to org/loc - so we remove the parameters from api here
          # loc/org are inherited from the ::Api::V2::BaseController in Foreman
          param :location_id, Integer, show: false
          param :organization_id, Integer, show: false
        end

        before_action :find_resource, only: %i[show update destroy]
        before_action :custom_find_resource, only: %i[utilization missing_hosts hosts users usergroups]

        api :GET, '/resource_quotas', N_('List all resource quotas')
        param_group :search_and_pagination, ::Api::V2::BaseController
        add_scoped_search_description_for(ForemanResourceQuota::ResourceQuota)
        def index
          @resource_quotas = resource_scope_for_index
        end

        api :GET, '/resource_quotas/:id/', N_('Show resource quota')
        param :id, :identifier, required: true
        def show
        end

        api :GET, '/resource_quotas/:id/utilization', N_('Show used resources of assigned hosts')
        param :id, :identifier, required: true
        def utilization
          @resource_quota.determine_utilization
          process_response @resource_quota
        end

        api :GET, '/resource_quotas/:id/missing_hosts',
          N_('Show resources could not be determined when calculating utilization')
        param :id, :identifier, required: true
        def missing_hosts
          process_response @resource_quota
        end

        api :GET, '/resource_quotas/:id/hosts', N_('Show hosts of a resource quota')
        param :id, :identifier, required: true
        def hosts
          process_response @resource_quota.hosts
        end

        api :GET, '/resource_quotas/:id/users', N_('Show users of a resource quota')
        param :id, :identifier, required: true
        def users
          process_response @resource_quota.users
        end

        api :GET, '/resource_quotas/:id/usergroups', N_('Show usergroups of a resource quota')
        param :id, :identifier, required: true
        def usergroups
          process_response @resource_quota.usergroups
        end

        def_param_group :resource_quota do
          param :resource_quota, Hash, required: true, action_aware: true do
            param :name, String, required: true, desc: N_('Name of the resource quota')
            param :description, String, required: false, desc: N_('Description of the resource quota')
            param :cpu_cores, Integer, required: false, desc: N_('Maximum number of CPU cores')
            param :memory_mb, Integer, required: false, desc: N_('Maximum memory in MiB')
            param :disk_gb, Integer, required: false, desc: N_('Maximum disk space in GiB')
          end
        end

        api :POST, '/resource_quotas/', N_('Create a resource quota')
        param_group :resource_quota, as: :create
        def create
          @resource_quota = ForemanResourceQuota::ResourceQuota.new(resource_quota_params)
          process_response @resource_quota.save
        end

        api :PUT, '/resource_quotas/:id/', N_('Update a resource quota')
        param :id, :identifier, required: true
        param_group :resource_quota
        def update
          process_response @resource_quota.update(resource_quota_params)
        end

        api :DELETE, '/resource_quotas/:id/', N_('Delete a resource quota')
        param :id, :identifier, required: true
        def destroy
          process_response @resource_quota.destroy
        end

        def resource_class
          ForemanResourceQuota::ResourceQuota
        end

        private

        def custom_find_resource
          @resource_quota = ForemanResourceQuota::ResourceQuota.find_by(id: params[:resource_quota_id])
          not_found unless @resource_quota
        end
      end
    end
  end
end
