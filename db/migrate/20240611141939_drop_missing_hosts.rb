# frozen_string_literal: true

class DropMissingHosts < ActiveRecord::Migration[6.1]
  def up
    drop_table :resource_quotas_missing_hosts
  end
end
