# frozen_string_literal: true

class RemoveUtilizationFromResourceQuotas < ActiveRecord::Migration[6.1]
  def change
    remove_column :resource_quotas, :utilization_cpu_cores, :integer
    remove_column :resource_quotas, :utilization_memory_mb, :integer
    remove_column :resource_quotas, :utilization_disk_gb, :integer
  end
end
