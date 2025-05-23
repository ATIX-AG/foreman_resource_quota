# frozen_string_literal: true

module ForemanResourceQuota
  module HostsHelper
    def resource_quota_select(form, user_quotas, selected, assignment_optional, host_quota)
      select_opts = { include_blank: false,
                      selected: selected }
      html_opts = { label: _('Resource Quota'),
                    required: !assignment_optional,
                    help_inline: if assignment_optional
                                   _('Define the Resource Quota this host counts to.')
                                 elsif !selected.nil? && (host_quota.nil? ||
                                       host_quota == ForemanResourceQuota::ResourceQuota.unassigned.id)
                                   format(_("Quota required! Choosing '%s' by default, change here if needed!"),
                                     user_quotas.find(selected))
                                 else
                                   _('Resource quota assignment required!')
                                 end }

      select_f form,
        :resource_quota_id,
        user_quotas,
        :id,
        :to_label,
        select_opts,
        html_opts
    end
  end
end
