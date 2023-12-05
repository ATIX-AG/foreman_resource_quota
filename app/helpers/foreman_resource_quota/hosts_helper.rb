# frozen_string_literal: true

module ForemanResourceQuota
  module HostsHelper
    def resource_quota_select(form, user_quotas)
      blank_opt = { include_blank: true }
      select_items = user_quotas.order(:name)
      select_f form,
        :resource_quota_id,
        select_items,
        :id,
        :to_label,
        blank_opt,
        label: _('Resource Quota'),
        help_inline: _('Define the Resource Quota this host counts to.')
    end
  end
end
