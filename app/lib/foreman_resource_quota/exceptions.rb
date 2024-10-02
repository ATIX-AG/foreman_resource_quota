# frozen_string_literal: true

module ForemanResourceQuota
  module Exceptions
    class ResourceQuotaException < Foreman::Exception; end
    class HostResourceQuotaEmptyException < ResourceQuotaException; end
    class ResourceLimitException < ResourceQuotaException; end
    class HostResourcesException < ResourceQuotaException; end
    class ResourceQuotaUtilizationException < ResourceQuotaException; end
    class HostNotFoundException < ResourceQuotaException; end
  end
end
