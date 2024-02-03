# frozen_string_literal: true

FactoryBot.modify do
  factory :host do
    trait :with_resource_quota do
      resource_quota { FactoryBot.create(:resource_quota) }
    end

    trait :with_resources_in_facts do
      # TODO: add facts resources for cpu, memory, and disk
    end

    trait :with_resources_in_vm_attributes do
      # TODO: add vm_attributes resources for cpu, memory, and disk
    end

    trait :with_resources_in_compute_attributes do
      # TODO: add comput_attributes resources for cpu, memory, and disk
    end

    trait :with_resources_in_compute_resource do
      # TODO: add compute_resource resources for cpu, memory, and disk
    end
  end
end
