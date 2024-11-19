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
      hosts_resources.size
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
    # Parameters:
    #   - exclude: an Array of host names to exclude from the utilization
    def missing_hosts(exclude: [])
      missing_hosts = {}
      active_resources.each do |single_resource|
        hosts_resources.where(single_resource => nil).find_each do |host_resources_item|
          host_name = host_resources_item.host.name
          next if exclude.include?(host_name)
          missing_hosts[host_name] ||= []
          missing_hosts[host_name] << single_resource
        end
      end
      missing_hosts
    end

    # Returns a Hash with the quota resources and their utilization as key-value pair
    # It returns always all resources, even if they are not used (nil in that case).
    # For example:
    #   {
    #     cpu_cores: 10,
    #     memory_mb: nil,
    #     disk_gb: 20,
    #   }
    # Parameters:
    #   - exclude: an Array of host names to exclude from the utilization
    def utilization(exclude: [])
      current_utilization = {
        cpu_cores: nil,
        memory_mb: nil,
        disk_gb: nil,
      }

      active_resources.each do |resource|
        current_utilization[resource] = 0
      end

      hosts_resources.each do |host_resources_item|
        next if exclude.include?(host_resources_item.host.name)

        active_resources.each do |resource|
          current_utilization[resource] += host_resources_item.send(resource).to_i
        end
      end

      current_utilization
    end

    def hosts_resources_as_hash
      resources_hash = hosts.map(&:name).index_with { {} }
      hosts_resources.each do |host_resources_item|
        active_resources do |resource_name|
          resources_hash[host_resources_item.host.name][resource_name] = host_resources_item.send(resource_name)
        end
      end
      resources_hash
    end

    def update_hosts_resources(hosts_resources_hash)
      # Only update hosts that are associated with this quota
      update_hosts = hosts.where(name: hosts_resources_hash.keys)
      update_hosts_ids = update_hosts.pluck(:name, :id).to_h
      hosts_resources_hash.each do |host_name, resources|
        # Update the host_resources without loading the whole host object
        host_resources_item = hosts_resources.find_by(host_id: update_hosts_ids[host_name])
        if host_resources_item
          host_resources_item.resources = resources
          host_resources_item.save
        else
          Rails.logger.warn "HostResources not found for host_name: #{host_name}"
        end
      end
    end

    def determine_utilization(additional_hosts = [])
      quota_hosts = (hosts | (additional_hosts))
      all_host_resources, missing_hosts_resources = call_utilization_helper(quota_hosts)
      update_hosts_resources(all_host_resources)

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
  end
end
