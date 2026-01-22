# frozen_string_literal: true

module ForemanResourceQuota
  module Concerns
    module RegistrationCommandsControllerExtensions
      extend ActiveSupport::Concern

      def plugin_data
        quotas = ResourceQuota.authorized(:view_resource_quotas)
                              .order(:name)
                              .map { |quota| { id: quota.id, name: quota.name } }
        data = { availableQuotas: quotas }

        super.merge(data)
      end
    end
  end
end
