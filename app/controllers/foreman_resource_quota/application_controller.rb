# frozen_string_literal: true

module ForemanResourceQuota
  class ApplicationController < ::ApplicationController
    def resource_class
      "ForemanResourceQuota::#{controller_name.singularize.classify}".constantize
    end
  end
end
