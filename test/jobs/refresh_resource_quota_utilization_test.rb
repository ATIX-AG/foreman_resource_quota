# frozen_string_literal: true

require 'test_plugin_helper'
require 'foreman_tasks/test_helpers'

class RefreshResourceQuotaUtilizationTest < ActiveSupport::TestCase
  include ForemanTasks::TestHelpers::WithInThreadExecutor

  setup do
    User.current = User.find_by(login: 'secret_admin')
    Setting[:resource_quota_global_no_action] = false
    Setting[:resource_quota_optional_assignment] = false
    User.current.resource_quota_is_optional = false

    stub_host_utilization({ cpu_cores: 2, memory_mb: 1024 * 4, disk_gb: 60 }, {})
    @quota = FactoryBot.create(:resource_quota, cpu_cores: 20, memory_mb: 1024 * 30, disk_gb: 512)

    @host_a = FactoryBot.create(:host, resource_quota: @quota)
    @host_b = FactoryBot.create(:host, resource_quota: @quota)
    @host_c = FactoryBot.create(:host, resource_quota: @quota)
    @host_d = FactoryBot.create(:host, resource_quota: @quota)
    @host_e = FactoryBot.create(:host, resource_quota: @quota)
    @quota.reload
  end

  test 'single resource quota utilization should be updated' do
    assert_equal({ cpu_cores: 5 * 2, memory_mb: 5 * 1024 * 4, disk_gb: 5 * 60 }, @quota.utilization)
    new_host_utilization = { cpu_cores: 3, memory_mb: 1024 * 5, disk_gb: 61 }
    quota_hosts_resources = {
      @host_a.name => new_host_utilization,
      @host_b.name => new_host_utilization,
      @host_c.name => new_host_utilization,
      @host_d.name => new_host_utilization,
      @host_e.name => new_host_utilization,
    }
    stub_quota_utilization_helper(quota_hosts_resources, {})
    ForemanTasks.sync_task(ForemanResourceQuota::Async::RefreshResourceQuotaUtilization)
    @quota.reload
    assert_equal({
      cpu_cores: 5 * new_host_utilization[:cpu_cores],
      memory_mb: 5 * new_host_utilization[:memory_mb],
      disk_gb: 5 * new_host_utilization[:disk_gb],
    }, @quota.utilization)
  end
end
