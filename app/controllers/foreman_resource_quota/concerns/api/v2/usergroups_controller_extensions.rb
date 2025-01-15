# frozen_string_literal: true

module ForemanResourceQuota
  module Concerns
    module Api
      module V2
        module UsergroupsControllerExtensions
          extend ::Apipie::DSL::Concern
          update_api(:create, :update) do
            param :usergroup, Hash do
              param :resource_quota_ids, Array, of: :number, required: false,
    desc: N_('Resource quota IDs to be associated with this user group. ')
            end
          end
        end
      end
    end
  end
end
