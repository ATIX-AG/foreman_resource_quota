# frozen_string_literal: true

FactoryBot.define do
  factory :resource_quota, class: 'ForemanResourceQuota::ResourceQuota' do
    sequence(:name) { |n| "test resource quota#{n}" }
    sequence(:description) { |n| "resource quota description#{n}" }
  end

  trait :with_existing_host_resources do
    transient do
      host_resources { [] }
    end

    after(:create) do |quota, evaluator|
      quota.cpu_cores = nil
      quota.memory_mb = nil
      quota.disk_gb = nil
      host = FactoryBot.create(:host, resource_quota: quota)
      host.host_resources.resources = evaluator.host_resources
      host.host_resources.save!
      quota.cpu_cores = evaluator.cpu_cores
      quota.memory_mb = evaluator.memory_mb
      quota.disk_gb = evaluator.disk_gb
      quota.save!
    end
  end
end
