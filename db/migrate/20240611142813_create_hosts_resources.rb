# frozen_string_literal: true

class CreateHostsResources < ActiveRecord::Migration[6.1]
  def change
    create_table :hosts_resources do |t|
      t.belongs_to :host, index: { unique: true }, foreign_key: true, null: false
      t.integer :cpu_cores, default: nil
      t.integer :memory_mb, default: nil
      t.integer :disk_gb, default: nil

      t.timestamps
    end

    create_table :resource_quotas_hosts do |t|
      t.belongs_to :host, index: { unique: true }, foreign_key: true, null: false
      t.belongs_to :resource_quota, foreign_key: true, null: false

      t.timestamps
    end
  end
end
