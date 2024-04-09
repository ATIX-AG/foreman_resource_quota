# frozen_string_literal: true

class CreateResourceQuotas < ActiveRecord::Migration[6.1]
  # rubocop: disable Metrics/AbcSize
  def change
    create_table :resource_quotas do |t|
      t.string :name, null: false
      t.text :description
      t.integer :cpu_cores, default: nil
      t.integer :memory_mb, default: nil
      t.integer :disk_gb, default: nil
      t.integer :utilization_cpu_cores, default: nil
      t.integer :utilization_memory_mb, default: nil
      t.integer :utilization_disk_gb, default: nil

      t.timestamps
    end

    create_table :resource_quotas_usergroups do |t|
      t.belongs_to :resource_quota
      t.belongs_to :usergroup
      t.timestamps
    end

    create_table :resource_quotas_users do |t|
      t.belongs_to :resource_quota
      t.belongs_to :user
      t.timestamps
    end

    create_table :resource_quotas_missing_hosts do |t|
      t.references :resource_quota, null: false, foreign_key: { to_table: :resource_quotas }
      t.references :missing_host, null: false, unique: true, foreign_key: { to_table: :hosts }
      t.boolean :no_cpu_cores, default: false
      t.boolean :no_memory_mb, default: false
      t.boolean :no_disk_gb, default: false
      t.timestamps
    end

    add_reference :hosts, :resource_quota, foreign_key: { to_table: :resource_quotas }
    add_column :users, :resource_quota_is_optional, :boolean, default: false
  end
  # rubocop: enable Metrics/AbcSize
end
