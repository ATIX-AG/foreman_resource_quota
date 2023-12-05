# frozen_string_literal: true

module ForemanResourceQuota
  class ResourceQuotaUsergroup < ApplicationRecord
    self.table_name = 'resource_quotas_usergroups'

    belongs_to :resource_quota, inverse_of: :resource_quota_usergroups
    belongs_to :usergroup, class_name: '::Usergroup', inverse_of: :resource_quota_usergroups
  end
end
