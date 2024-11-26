require 'test_plugin_helper'
require 'foreman_tasks/test_helpers'

class RefreshResourceQuotaUtilizationTest < ActiveSupport::TestCase
  include ForemanTasks::TestHelpers::WithInThreadExecutor
  setup do
    User.current = User.find_by(login: 'secret_admin')
    @quota = FactoryBot.create(:resource_quota)
    @host = FactoryBot.create(:resource_quota)
  end

  test 'resource quota utilization should be updated' do
    @host.host_resources.cpu_cores = 10
    ForemanTasks.sync_task(ForemanResourceQuota::Async::RefreshResourceQuotaUtilization)
    @hosts.each(&:reload)
    assert_equal InsightsClientReportStatus::NOT_MANAGED, @host4.get_status(InsightsClientReportStatus).status
  end
end
