# frozen_string_literal: true

module ForemanResourceQuota
  class ResourceQuotaHost < ApplicationRecord
    self.table_name = 'resource_quotas_hosts'

    belongs_to :resource_quota, class_name: 'ResourceQuota'
    belongs_to :host, class_name: '::Host::Managed'
  end
end
