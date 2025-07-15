# frozen_string_literal: true

# rubocop: disable Metrics/BlockLength
Foreman::Plugin.register :foreman_resource_quota do
  requires_foreman '>= 3.13'
  # Apipie
  apipie_documented_controllers ["#{ForemanResourceQuota::Engine.root}" \
                                 '/app/controllers/foreman_resource_quot/api/v2/*.rb']

  register_gettext

  # Add permissions
  security_block :foreman_resource_quota do
    permission :view_resource_quotas,
      { 'foreman_resource_quota/resource_quotas': %i[index welcome auto_complete_search],
        'foreman_resource_quota/api/v2/resource_quotas': %i[index show utilization missing_hosts hosts users usergroups
                                                            auto_complete_search],
        'foreman_resource_quota/api/v2/resource_quotas/:resource_quota_id/': %i[utilization missing_hosts hosts users
                                                                                usergroups] },
      resource_type: 'ForemanResourceQuota::ResourceQuota'
    permission :create_resource_quotas,
      { 'foreman_resource_quota/resource_quotas': %i[new create],
        'foreman_resource_quota/api/v2/resource_quotas': %i[create] },
      resource_type: 'ForemanResourceQuota::ResourceQuota'
    permission :edit_resource_quotas,
      { 'foreman_resource_quota/resource_quotas': %i[edit update],
        'foreman_resource_quota/api/v2/resource_quotas': %i[update] },
      resource_type: 'ForemanResourceQuota::ResourceQuota'
    permission :destroy_resource_quotas,
      { 'foreman_resource_quota/resource_quotas': %i[destroy],
        'foreman_resource_quota/api/v2/resource_quotas': %i[destroy] },
      resource_type: 'ForemanResourceQuota::ResourceQuota'

    # TODO: Evaluate whether host/user/usergroup permission extensions are necessary
  end

  # Add a permissions to default roles (Viewer and Manager)
  role 'Resource Quota Manager', %i[view_resource_quotas
                                    create_resource_quotas
                                    edit_resource_quotas
                                    destroy_resource_quotas
                                    view_hosts
                                    edit_hosts
                                    view_users
                                    edit_users]
  role 'Resource Quota User', %i[view_resource_quotas
                                 view_hosts
                                 view_users
                                 view_usergroups]
  add_all_permissions_to_default_roles

  # add controller parameter extension
  parameter_filter User, { resource_quotas: [], resource_quota_ids: [] }, :resource_quota_is_optional
  parameter_filter Usergroup, { resource_quotas: [], resource_quota_ids: [] }
  parameter_filter Host::Managed, :resource_quota_id

  # add UI menu extension
  add_menu_item :top_menu, :resource_quotas,
    url_hash: { controller: 'foreman_resource_quota/resource_quotas', action: :index },
    caption: N_('Resource Quotas'),
    parent: :configure_menu,
    after: :common_parameters

  # add API extension
  extend_rabl_template 'api/v2/hosts/main', 'foreman_resource_quota/api/v2/hosts/resource_quota'
  extend_rabl_template 'api/v2/users/main', 'foreman_resource_quota/api/v2/users/resource_quota'
  extend_rabl_template 'api/v2/usergroups/main', 'foreman_resource_quota/api/v2/usergroups/resource_quota'

  # add UI user/usergroup/hosts extension
  extend_page 'users/_form' do |cx|
    cx.add_pagelet :main_tabs,
      id: :quota_user_tab,
      name: N_('Resource Quota'),
      resource_type: :user,
      partial: 'users/form_quota_tab'
  end
  extend_page 'usergroups/_form' do |cx|
    cx.add_pagelet :main_tabs,
      id: :quota_usergroup_tab,
      name: N_('Resource Quota'),
      resource_type: :usergroup,
      partial: 'users/form_quota_tab'
  end
  extend_page 'hosts/_form' do |cx|
    cx.add_pagelet :main_tab_fields,
      id: :quota_hosts_tab_fields,
      resource_type: :host,
      partial: 'hosts/form_quota_fields'
  end

  # Add global Foreman settings
  settings do
    category :provisioning do
      setting 'resource_quota_optional_assignment',
        type: :boolean,
        default: false,
        full_name: N_('Resource Quota optional assignment'),
        description: N_('Make the assignment of a Resource Quota, during the host creation process, optional for
                        everyone. If this is true, user-specific "optional assignment" configurations are neglected.')
      setting 'resource_quota_global_no_action',
        type: :boolean,
        default: true,
        full_name: N_('Global Resource Quota no action'),
        description: N_('Take no action when a Resource Quota is exceeded.')
      # Future: Overwrite quota-specific "out of resource"-action and take no ..
    end
  end
  extend_page 'hosts/_list' do |context|
    context.with_profile :resource_quota, _('Resource Quota'), default: true do
      add_pagelet :hosts_table_column_header, key: :resource_quota, label: s_('Resource Quota'),
        sortable: true, width: '10%', class: 'hidden-xs'
      add_pagelet :hosts_table_column_content, key: :resource_quota,
        callback: ->(host) { host.resource_quota&.name || _('Not available') }, class: 'hidden-xs ellipsis'
    end
  end
end
# rubocop: enable Metrics/BlockLength
