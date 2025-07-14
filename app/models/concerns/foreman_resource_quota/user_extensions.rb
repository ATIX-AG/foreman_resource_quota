# frozen_string_literal: true

module ForemanResourceQuota
  module UserExtensions
    extend ActiveSupport::Concern
    included do # rubocop:disable Metrics/BlockLength
      after_create :set_unassigned_quota

      has_many :resource_quotas_users, class_name: 'ForemanResourceQuota::ResourceQuotaUser', dependent: :destroy,
        inverse_of: :user
      has_many :resource_quotas, class_name: 'ForemanResourceQuota::ResourceQuota', through: :resource_quotas_users
      attribute :resource_quota_is_optional, :boolean, default: false

      scoped_search relation: :resource_quotas, on: :name, complete_value: true, rename: :resource_quota

      def quotas_with_usergroups
        quotas = []
        usergroups.each do |group|
          quotas << group.resource_quotas
        end
        quotas << resource_quotas
        ForemanResourceQuota::ResourceQuota.where(id: quotas.flatten.map(&:id))
      end

      def assignable_resource_quotas
        resource_quotas.assignable
      end

      def quota_assignment_optional?
        Setting['resource_quota_optional_assignment'] || resource_quota_is_optional
      end

      def show_unassigned_hosts_warning?
        return false if Setting['resource_quota_optional_assignment']
        (admin? &&
         !ForemanResourceQuota::ResourceQuota.unassigned.hosts.empty?) ||
          (!admin? &&
           !resource_quota_is_optional &&
           !ForemanResourceQuota::ResourceQuota.unassigned.hosts.where(owner: self).empty?)
      end

      private

      def set_unassigned_quota
        return if resource_quotas.include?(ForemanResourceQuota::ResourceQuota.unassigned)

        resource_quotas << ForemanResourceQuota::ResourceQuota.unassigned
      end
    end
  end
end
