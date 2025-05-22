# frozen_string_literal: true

class DropMissingHosts < ActiveRecord::Migration[6.1]
  def change
    drop_table :resource_quotas_missing_hosts do |t|
      t.references :resource_quota, null: false, foreign_key: { to_table: :resource_quotas }
      t.references :missing_host, null: false, unique: true, foreign_key: { to_table: :hosts }
      t.boolean :no_cpu_cores, default: false
      t.boolean :no_memory_mb, default: false
      t.boolean :no_disk_gb, default: false
      t.timestamps
    end
  end
end
