# frozen_string_literal: true

module ForemanResourceQuota
  module UsergroupExtensions
    extend ActiveSupport::Concern
    included do
      after_create :set_unassigned_quota

      has_many :resource_quotas_usergroups, class_name: 'ForemanResourceQuota::ResourceQuotaUsergroup',
        dependent: :destroy, inverse_of: :usergroup
      has_many :resource_quotas, class_name: 'ForemanResourceQuota::ResourceQuota', through: :resource_quotas_usergroups

      scoped_search relation: :resource_quotas, on: :name, complete_value: true, rename: :resource_quota

      def assignable_resource_quotas
        resource_quotas.assignable
      end

      def quota_assignment_optional?
        Setting['resource_quota_optional_assignment']
      end

      private

      def set_unassigned_quota
        return if resource_quotas.include?(ForemanResourceQuota::ResourceQuota.unassigned)

        resource_quotas << ForemanResourceQuota::ResourceQuota.unassigned
      end
    end
  end
end
