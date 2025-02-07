# frozen_string_literal: true

module ForemanResourceQuota
  module Concerns
    module Api
      module V2
        module UsersControllerExtensions
          extend ::Apipie::DSL::Concern
          update_api(:create, :update) do
            param :user, Hash do
              param :resource_quota_ids, Array, of: :number, required: false,
                desc: N_('Resource Quota IDs to be associated with this user. ')
              param :resource_quota_is_optional, :bool,
                desc: N_('When set to "true", it is optional for a user to assign a quota when creating new hosts.
                                   The default value is "false".')
            end
          end
        end
      end
    end
  end
end
