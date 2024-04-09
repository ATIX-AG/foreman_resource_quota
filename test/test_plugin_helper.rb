# frozen_string_literal: true

# This calls the main test_helper in Foreman-core
require 'test_helper'

# Add plugin to FactoryBot's paths
FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryBot.reload

module ActionController
  class TestCase
    def set_session_user(user = :admin, org = :empty_organization)
      user = users(user) unless user.is_a?(User)
      org = taxonomies(org) unless org.is_a?(Organization)
      { user: user.id, expires_at: 5.minutes.from_now, organization_id: org.id }
    end

    # Custom assertion method for checking if a given quota is equal to the expected values.
    # The order of the expected values matters: [name, description, cpu_cores, memory_mb, disk_gb]
    def assert_quota_equal(expexted_list, quota)
      attributes = %i[name description cpu_cores memory_mb disk_gb]
      attributes.each_with_index do |attr, index|
        if expexted_list[index].nil?
          assert_nil quota.public_send(attr)
        else
          assert_equal expexted_list[index], quota.public_send(attr), "#{attr} mismatch"
        end
      end
    end
  end
end

def stub_quota_utilization(return_utilization, return_missing_hosts)
  ForemanResourceQuota::ResourceQuota.any_instance.stubs(:call_utilization_helper)
                                     .returns([return_utilization, return_missing_hosts])
  ForemanResourceQuota::ResourceQuota.any_instance.stubs(:missing_hosts)
                                     .returns(return_missing_hosts)
  ForemanResourceQuota::ResourceQuota.any_instance.stubs(:missing_hosts=)
                                     .returns
  ForemanResourceQuota::ResourceQuota.any_instance.stubs(:utilization)
                                     .returns(return_utilization)
  ForemanResourceQuota::ResourceQuota.any_instance.stubs(:utilization=)
                                     .returns
end

def stub_host_utilization(return_utilization, return_missing_hosts)
  Host::Managed.any_instance.stubs(:call_utilization_helper)
               .returns([return_utilization, return_missing_hosts])
end
