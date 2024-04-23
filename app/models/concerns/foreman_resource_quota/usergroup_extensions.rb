# frozen_string_literal: true

module ForemanResourceQuota
  module UsergroupExtensions
    extend ActiveSupport::Concern
    included do
      has_many :resource_quotas_usergroups, class_name: 'ForemanResourceQuota::ResourceQuotaUsergroup',
        dependent: :destroy, inverse_of: :usergroup
      has_many :resource_quotas, class_name: 'ForemanResourceQuota::ResourceQuota', through: :resource_quotas_usergroups

      scoped_search relation: :resource_quotas, on: :name, complete_value: true, rename: :resource_quota
    end
  end
end
