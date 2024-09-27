class DropMissingHosts < ActiveRecord::Migration[6.1]
  def change
    drop_table :resource_quotas_missing_hosts
  end
end
