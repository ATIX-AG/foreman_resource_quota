# frozen_string_literal: true

module ForemanResourceQuota
  module UserExtensions
    extend ActiveSupport::Concern
    included do
      has_many :resource_quota_users, class_name: 'ForemanResourceQuota::ResourceQuotaUser', dependent: :destroy,
        inverse_of: :user
      has_many :resource_quotas, class_name: 'ForemanResourceQuota::ResourceQuota', through: :resource_quota_users
      attribute :resource_quota_is_optional, :boolean, default: false

      scoped_search relation: :resource_quotas, on: :name, complete_value: true, rename: :resource_quota
    end
  end
end
