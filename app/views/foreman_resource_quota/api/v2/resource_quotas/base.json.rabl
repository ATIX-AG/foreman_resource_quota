# frozen_string_literal: true

object @resource_quota

attributes :name, :id, :description, :cpu_cores, :memory_mb, :disk_gb, :number_of_hosts, :number_of_users,
  :number_of_usergroups, :number_of_missing_hosts, :utilization
