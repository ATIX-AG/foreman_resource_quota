# frozen_string_literal: true

module ForemanResourceQuota
  class ResourceQuotasController < ::ForemanResourceQuota::ApplicationController
    include Foreman::Controller::AutoCompleteSearch
    include Foreman::Controller::Parameters::ResourceQuota

    before_action :find_resource, only: %i[edit update destroy]

    def index
      @resource_quotas = resource_base.search_for(params[:search], order: params[:order]).paginate(page: params[:page],
        per_page: params[:per_page])
      # TODO: Check necessitiy/purpose of authorizer
      # AuthorizerHelper#authorizer uses controller_name as variable name, but it fails with namespaces
      # @authorizer = Authorizer.new(User.current, collection: @resource_quotas)
    end

    def new
      @resource_quota = ResourceQuota.new
    end

    def create
      @resource_quota = ResourceQuota.new(resource_quota_params)
      if @resource_quota.save
        process_success
      else
        process_error
      end
    end

    def edit
    end

    def update
      if @resource_quota.update(resource_quota_params)
        process_success
      else
        process_error
      end
    end

    def destroy
      if @resource_quota.destroy
        process_success
      else
        process_error
      end
    end
  end
end
