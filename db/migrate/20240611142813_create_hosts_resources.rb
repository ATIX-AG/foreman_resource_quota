class CreateHostsResources < ActiveRecord::Migration[6.1]
  def change
    create_table :hosts_resources do |t|
      t.references :host, foreign_key: true, unique: true, null: false
      t.references :resource_quota, foreign_key: true, default: nil
      t.integer :cpu_cores, default: nil
      t.integer :memory_mb, default: nil
      t.integer :disk_gb, default: nil

      t.timestamps
    end
  end
end
