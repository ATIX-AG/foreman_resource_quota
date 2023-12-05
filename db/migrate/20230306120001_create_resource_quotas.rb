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
    add_reference :hosts, :resource_quota, foreign_key: { to_table: :resource_quotas }
    add_column :users, :resource_quota_is_optional, :boolean, default: false
  end
  # rubocop: enable Metrics/AbcSize
end
