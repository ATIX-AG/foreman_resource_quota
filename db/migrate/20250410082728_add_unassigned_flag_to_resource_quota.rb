# frozen_string_literal: true

class AddUnassignedFlagToResourceQuota < ActiveRecord::Migration[6.1]
  def change
    add_column :resource_quotas, :unassigned, :bool, null: false, default: false
  end
end
