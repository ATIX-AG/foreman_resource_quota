# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class HostsHelperTest < ActionView::TestCase
    include ::FormHelper
    include ForemanResourceQuota::HostsHelper

    test 'host edit page form' do
      @host = FactoryBot.create :host
      quotas = []
      quotas << (FactoryBot.create :resource_quota)
      quotas << (FactoryBot.create :resource_quota)
      quotas << (FactoryBot.create :resource_quota)
      as_admin { quotas.each(&:save!) }

      form = ''
      as_admin do
        form = form_for(@host) do |f|
          resource_quota_select(f, ResourceQuota.all)
        end
      end
      quotas.each do |quota|
        assert form[quota.name]
      end
    end
  end
end
