# frozen_string_literal: true

module ForemanResourceQuota
  class ResourceQuota < ApplicationRecord
    include ResourceQuotaHelper
    include Exceptions
    include Authorizable
    include Parameterizable::ByIdName
    extend FriendlyId
    friendly_id :name
    audited

    self.table_name = 'resource_quotas'

    has_many :resource_quotas_users, class_name: 'ResourceQuotaUser', inverse_of: :resource_quota, dependent: :destroy
    has_many :resource_quotas_usergroups, class_name: 'ResourceQuotaUsergroup', inverse_of: :resource_quota,
      dependent: :destroy
    has_many :resource_quotas_missing_hosts, class_name: 'ResourceQuotaMissingHost', inverse_of: :resource_quota,
      dependent: :destroy
    has_many :hosts, class_name: '::Host::Managed', dependent: :nullify
    has_many :users, class_name: '::User', through: :resource_quotas_users
    has_many :usergroups, class_name: '::Usergroup', through: :resource_quotas_usergroups

    validates :name, presence: true, uniqueness: true

    scoped_search on: :name, complete_value: true
    scoped_search on: :id, complete_enabled: false, only_explicit: true, validator: ScopedSearch::Validators::INTEGER

    def number_of_hosts
      hosts.size
    end

    def number_of_users
      users.size
    end

    def number_of_usergroups
      usergroups.size
    end

    def number_of_missing_hosts
      missing_hosts.size
    end

    # Returns a Hash with host name as key and a list of missing resources as value
    #     { <host name>: [<list of missing resources>] }
    #     for example:
    #     {
    #       "host_a": [ :cpu_cores, :disk_gb ],
    #       "host_b": [ :memory_mb ],
    #     }
    def missing_hosts
      # Initialize default value as an empty array
      missing_hosts_list = Hash.new { |hash, key| hash[key] = [] }
      resource_quotas_missing_hosts.each do |missing_host_rel|
        host_name = missing_host_rel.missing_host.name
        missing_hosts_list[host_name] << :cpu_cores if missing_host_rel.no_cpu_cores
        missing_hosts_list[host_name] << :memory_mb if missing_host_rel.no_memory_mb
        missing_hosts_list[host_name] << :disk_gb if missing_host_rel.no_disk_gb
      end
      missing_hosts_list
    end

    # Set the hosts that are listed in resource_quotas_missing_hosts
    # Parameters:
    #   - val: Hash of host names and list of missing resources
    #     { <host name>: [<list of missing resources>] }
    #     for example:
    #     {
    #       "host_a": [ :cpu_cores, :disk_gb ],
    #       "host_b": [ :memory_mb ],
    #     }
    def missing_hosts=(val)
      # Delete all entries and write new ones
      resource_quotas_missing_hosts.delete_all
      val.each do |host_name, missing_resources|
        add_missing_host(host_name, missing_resources)
      end
    end

    def utilization
      {
        cpu_cores: utilization_cpu_cores,
        memory_mb: utilization_memory_mb,
        disk_gb: utilization_disk_gb,
      }
    end

    def utilization=(val)
      update_single_utilization(:cpu_cores, val)
      update_single_utilization(:memory_mb, val)
      update_single_utilization(:disk_gb, val)
    end

    def determine_utilization(additional_hosts = [])
      quota_hosts = (hosts | (additional_hosts))
      quota_utilization, missing_hosts_resources = call_utilization_helper(quota_hosts)
      update(utilization: quota_utilization)
      update(missing_hosts: missing_hosts_resources)
      Rails.logger.warn create_hosts_resources_warning(missing_hosts_resources) unless missing_hosts.empty?
    rescue StandardError => e
      Rails.logger.error("An error occured while determining resources for quota '#{name}': #{e}")
      raise e
    end

    def to_label
      name
    end

    def active_resources
      resources = []
      %i[cpu_cores memory_mb disk_gb].each do |res|
        resources << res unless self[res].nil?
      end
      resources
    end

    private

    # Wrap into a function for easier testing
    def call_utilization_helper(quota_hosts)
      utilization_from_resource_origins(active_resources, quota_hosts)
    end

    def create_hosts_resources_warning(missing_hosts_resources)
      warn_text = +"Could not determines resources for #{missing_hosts_resources.size} hosts:"
      missing_hosts_resources.each do |host_name, missing_resources|
        warn_text << "  '#{host_name}': '#{missing_resources}'\n" unless missing_resources.empty?
      end
    end

    def update_single_utilization(attribute, val)
      return unless val.key?(attribute.to_sym) || val.key?(attribute.to_s)
      update("utilization_#{attribute}": val[attribute.to_sym] || val[attribute.to_s])
    end

    def add_missing_host(host_name, missing_resources)
      return if missing_resources.empty?

      host = Host::Managed.find_by(name: host_name)
      raise HostNotFoundException if host.nil?

      resource_quotas_missing_hosts << ResourceQuotaMissingHost.new(
        missing_host: host,
        resource_quota: self,
        no_cpu_cores: missing_resources.include?(:cpu_cores),
        no_memory_mb: missing_resources.include?(:memory_mb),
        no_disk_gb: missing_resources.include?(:disk_gb)
      )
    end
  end
end
