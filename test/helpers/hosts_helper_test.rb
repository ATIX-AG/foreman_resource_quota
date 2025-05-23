# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanResourceQuota
  class HostsHelperTest < ActionView::TestCase
    include ::FormHelper
    include ForemanResourceQuota::HostsHelper

    context 'optional quota assignment at host creation' do
      def setup
        @unassigned = ForemanResourceQuota::ResourceQuota.where(
          name: 'Unassigned',
          unassigned: true,
          description: 'Here, you can see all hosts without a dedicated quota.'
        ).first_or_create
        @quotas = []
        @quotas << (FactoryBot.create :resource_quota)
        @quotas << (FactoryBot.create :resource_quota)
        @quotas << (FactoryBot.create :resource_quota)
        as_admin { @quotas.each(&:save!) }
        @host = FactoryBot.create :host, resource_quota: @quotas.first
      end

      test 'host edit page form with unassigned options for optional assignement' do
        Setting[:resource_quota_optional_assignment] = true
        form = ''
        as_admin do
          form = form_for(@host) do |f|
            # def resource_quota_select(form, user_quotas, selected, assignment_optional, host_quota)
            resource_quota_select(f, ResourceQuota.all, @host.resource_quota.id, true, @host.resource_quota_id)
          end
        end

        @quotas.each do |quota|
          assert form[quota.name]
        end
        assert form[@unassigned.name]
        assert form['Define the Resource Quota this host counts to.']
      end

      test 'host edit page form without unassigned options for mandatory assignment' do
        Setting[:resource_quota_optional_assignment] = false
        form = ''
        as_admin do
          form = form_for(@host) do |f|
            # def resource_quota_select(form, user_quotas, selected, assignment_optional, host_quota)
            resource_quota_select(f, ResourceQuota.assignable, @host.resource_quota.id, false, @host.resource_quota_id)
          end
        end

        @quotas.each do |quota|
          assert form[quota.name]
        end
        assert_nil form[@unassigned.name]
        assert form['Resource quota assignment required!']
      end

      test 'No quota selectable if no quota is given' do
        as_admin { @quotas.each(&:destroy) }
        Setting[:resource_quota_optional_assignment] = false
        @host.reload.resource_quota_id
        assert_equal @host.resource_quota_id, @unassigned.id
        form = ''
        as_admin do
          form = form_for(@host) do |f|
            # def resource_quota_select(form, user_quotas, selected, assignment_optional, host_quota)
            resource_quota_select(f, ResourceQuota.assignable, nil, false, @host.resource_quota_id)
          end
        end

        assert_nil form[@unassigned.name]
        assert form['Resource quota assignment required!']
      end
    end
  end
end
