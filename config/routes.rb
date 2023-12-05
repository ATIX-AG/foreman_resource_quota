# frozen_string_literal: true

# rubocop: disable Metrics/BlockLength
Rails.application.routes.draw do
  scope :foreman_resource_quota, path: 'foreman_resource_quota' do
    resources :resource_quotas, except: %i[show], controller: 'foreman_resource_quota/resource_quotas' do
      collection do
        get 'auto_complete_search'
      end
    end
  end

  namespace :foreman_resource_quota do
    resources :resource_quotas, except: %i[show] do
      collection do
        get 'help', action: :welcome
        get 'auto_complete_search'
      end
    end

    # API routes
    namespace :api, defaults: { format: 'json' } do
      scope '(:apiv)',
        module: :v2,
        defaults: { apiv: 'v2' },
        apiv: /v1|v2/,
        constraints: ApiConstraints.new(version: 2, default: true) do
        resources :resource_quotas, except: %i[new edit] do
          collection do
            get 'auto_complete_search'
          end
          constraints(id: %r{[^/]+}) do
            get 'utilization'
            get 'hosts'
            get 'users'
            get 'usergroups'
          end
        end
      end
    end
  end
end
# rubocop: enable Metrics/BlockLength
