# frozen_string_literal: true

module Foreman
  module Controller
    module Parameters
      module ResourceQuota
        extend ActiveSupport::Concern

        class_methods do
          def resource_quota_params_filter
            Foreman::ParameterFilter.new(::ForemanResourceQuota::ResourceQuota).tap do |filter|
              filter.permit :name
              filter.permit :description
              filter.permit :cpu_cores
              filter.permit :memory_mb
              filter.permit :disk_gb
            end
          end
        end

        def resource_quota_params
          param_name = parameter_filter_context.api? ? 'resource_quota' : 'foreman_resource_quota_resource_quota'
          self.class.resource_quota_params_filter.filter_params(params, parameter_filter_context, param_name)
        end
      end
    end
  end
end
