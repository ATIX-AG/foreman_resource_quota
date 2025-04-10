# frozen_string_literal: true

# Default Quota "Unassigned"
ForemanResourceQuota::ResourceQuota.without_auditing do # rubocop:disable Metrics/BlockLength
  unassigned = ForemanResourceQuota::ResourceQuota.where(
    name: 'Unassigned',
    unassigned: true,
    description: 'Here, you can see all hosts without a dedicated quota.'
  ).first_or_create

  # Add default quota to all users and usergroups
  User.without_auditing do
    User.all.each do |user|
      unless user.resource_quotas.include?(unassigned)
        user.resource_quotas << unassigned
        user.save!
      end
    end
  end

  Usergroup.without_auditing do
    Usergroup.all.each do |usergroup|
      unless usergroup.resource_quotas.include?(unassigned)
        usergroup.resource_quotas << unassigned
        usergroup.save!
      end
    end
  end

  # Move all hosts without a quota to quota "Unassigned"
  Host.without_auditing do
    Host.all.each do |host|
      host.update(resource_quota: unassigned) if host.resource_quota.nil?
    end
  end
end
