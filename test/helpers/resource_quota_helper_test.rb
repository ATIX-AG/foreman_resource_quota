# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class ResourceQuotaHelperTest < ActiveSupport::TestCase
    include ForemanResourceQuota::ResourceQuotaHelper

    test 'resource quota natural name by type' do
      assert_equal 'CPU cores', natural_resource_name_by_type(:cpu_cores)
      assert_equal 'Memory (MB)', natural_resource_name_by_type(:memory_mb)
      assert_equal 'Disk space (GB)', natural_resource_name_by_type(:disk_gb)
    end

    test 'builds missing resource per host list' do
      hosts = []
      hosts << (FactoryBot.create :host)
      hosts << (FactoryBot.create :host)
      quota_utilization = %i[cpu_cores memory_mb disk_gb]
      missing_host_res = build_missing_resources_per_host_list(hosts, quota_utilization)
      assert_equal quota_utilization, missing_host_res[hosts[0].id]
      assert_equal quota_utilization, missing_host_res[hosts[1].id]
    end
  end
end
