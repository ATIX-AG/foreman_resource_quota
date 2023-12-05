# frozen_string_literal: true

FactoryBot.define do
  factory :resource_quota, class: 'ForemanResourceQuota::ResourceQuota' do
    sequence(:name) { |n| "test resource quota#{n}" }
    sequence(:description) { |n| "resource quota description#{n}" }
  end
  # TODO: Evaluate adding fixtures for resource origins
end
