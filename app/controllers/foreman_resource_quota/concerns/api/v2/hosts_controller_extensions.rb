# frozen_string_literal: true

module ForemanResourceQuota
  module Concerns
    module Api
      module V2
        module HostsControllerExtensions
          extend ::Apipie::DSL::Concern
          update_api(:create, :update) do
            param :host, Hash do
              param :resource_quota_id, :number, required: false,
                desc: N_('Resource Quota ID.
                         This field is required if the setting `resource_quota_optional_assignment` is set to false.')
            end
          end
        end
      end
    end
  end
end
