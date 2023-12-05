# frozen_string_literal: true

module ForemanResourceQuota
  class ResourceQuota < ApplicationRecord
    include ResourceQuotaHelper
    include Authorizable
    include Parameterizable::ByIdName
    extend FriendlyId
    friendly_id :name
    audited

    self.table_name = 'resource_quotas'

    has_many :resource_quota_users, class_name: 'ResourceQuotaUser', inverse_of: :resource_quota, dependent: :destroy
    has_many :users, class_name: '::User', through: :resource_quota_users
    has_many :resource_quota_usergroups, class_name: 'ResourceQuotaUsergroup', inverse_of: :resource_quota,
      dependent: :destroy
    has_many :usergroups, class_name: '::Usergroup', through: :resource_quota_usergroups
    has_many :hosts, class_name: '::Host::Managed', dependent: :nullify

    validates :name, presence: true, uniqueness: true

    scoped_search on: :name, complete_value: true
    scoped_search on: :id, complete_enabled: false, only_explicit: true, validator: ScopedSearch::Validators::INTEGER

    attribute :utilization, :jsonb, default: {}
    attribute :missing_hosts, :jsonb, default: {}

    def number_of_hosts
      hosts.size
    end

    def number_of_users
      users.size
    end

    def number_of_usergroups
      usergroups.size
    end

    def determine_utilization(additional_hosts: [])
      quota_hosts = (hosts | (additional_hosts))
      self.utilization, self.missing_hosts = call_utilization_helper(quota_hosts)

      print_warning(missing_hosts, quota_hosts) unless missing_hosts.empty?
    rescue StandardError => e
      print_error(e) # print error log here and forward error
      raise e
    end

    def to_label
      name
    end

    private

    # Wrap into a function for better testing
    def call_utilization_helper(quota_hosts)
      utilization_from_resource_origins(active_resources, quota_hosts)
    end

    def active_resources
      resources = []
      %i[cpu_cores memory_mb disk_gb].each do |res|
        resources << res unless self[res].nil?
      end
      resources
    end

    def print_warning(missing_hosts, hosts)
      warn_text = "Could not determines resources for #{utilization_hash.missing_hosts.size} hosts:"
      missing_hosts.each do |host_id, missing_resources|
        missing_host = hosts.find { |obj| obj.id == host_id }
        warn_text << "  '#{missing_host.name}': '#{missing_resources}'\n"
      end
      Rails.logger.warn warn_text
    end

    def print_error(err)
      Rails.logger.error("An error occured while determining resources for quota '#{name}': #{err}")
    end
  end
end
