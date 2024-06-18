class CreateHostsResources < ActiveRecord::Migration[6.1]
  def change
    create_table :hosts_resources do |t|
      t.references :resource_quota, foreign_key: true
      t.references :host, foreign_key: true, unique: true, null: false
      t.integer :cpu_cores
      t.integer :memory_mb
      t.integer :disk_gb

      t.timestamps
    end
  end
end
