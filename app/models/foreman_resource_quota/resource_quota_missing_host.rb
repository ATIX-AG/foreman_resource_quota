# frozen_string_literal: true

module ForemanResourceQuota
  class ResourceQuotaMissingHost < ApplicationRecord
    self.table_name = 'resource_quotas_missing_hosts'

    belongs_to :resource_quota, inverse_of: :resource_quotas_missing_hosts
    belongs_to :missing_host, class_name: '::Host::Managed', inverse_of: :resource_quota_missing_resources
  end
end
