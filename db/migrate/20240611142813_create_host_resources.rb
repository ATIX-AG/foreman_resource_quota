class CreateHostResources < ActiveRecord::Migration[6.1]
  def change
    create_table :host_resources do |t|
      t.belongs_to :host, foreign_key: true
      t.belongs_to :resource_quota, foreign_key: true
      t.integer :cpu_cores
      t.integer :memory_mb
      t.integer :disk_gb

      t.timestamps
    end
  end
end
