# frozen_string_literal: true

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'resource_quota', 'resource_quotas'
  inflect.irregular 'host_resources', 'hosts_resources'
end
