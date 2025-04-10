# frozen_string_literal: true

module ForemanResourceQuota
  module Concerns
    module Api
      module V2
        module HostsControllerExtensions
          extend ActiveSupport::Concern

          included do
            before_action :check_if_quota_is_set, only: %i[create update]
          end

          extend ::Apipie::DSL::Concern

          update_api(:create, :update) do
            param :host, Hash do
              param :resource_quota_id, :number, required: false,
                desc: N_('Resource Quota ID.
                         This field is required if the setting `resource_quota_optional_assignment` is set to false.')
            end
          end

          private

          def check_if_quota_is_set # rubocop:disable Metrics/AbcSize
            return if User.current.quota_assignment_optional?
            quota = if User.current&.admin?
                      ResourceQuota.where(id: params['host']['resource_quota_id']).first
                    else
                      User.current.resource_quotas.where(id: params['host']['resource_quota_id']).first
                    end
            return unless quota.nil? || quota.unassigned?
            render_error :custom_error, status: :unprocessable_entity,
locals: { message: 'No valid resource quota provided' }
          end
        end
      end
    end
  end
end
