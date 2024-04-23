# frozen_string_literal: true

module ForemanResourceQuota
  class ResourceQuotaUser < ApplicationRecord
    self.table_name = 'resource_quotas_users'

    belongs_to :resource_quota, inverse_of: :resource_quotas_users
    belongs_to :user, class_name: '::User', inverse_of: :resource_quotas_users
  end
end
