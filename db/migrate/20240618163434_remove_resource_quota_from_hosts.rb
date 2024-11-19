# frozen_string_literal: true

class RemoveResourceQuotaFromHosts < ActiveRecord::Migration[6.1]
  def change
    remove_reference :hosts, :resource_quota, foreign_key: true
  end
end
