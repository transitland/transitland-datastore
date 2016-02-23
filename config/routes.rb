# host, protocol, port for full URLs
if Figaro.env.transitland_datastore_host.present?
  default_url_options = {
    host: Figaro.env.transitland_datastore_host.match(/:\/\/([^:]+)/)[1],
    protocol: Figaro.env.transitland_datastore_host.split('://')[0]
  }
  if (port_match = Figaro.env.transitland_datastore_host.match(/:(\d+)/))
    default_url_options[:port] = port_match[1]
  end
else
  default_url_options = {
    host: 'localhost',
    protocol: 'http',
    port: '3000'
  }
end
Rails.application.routes.default_url_options = default_url_options

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/onestop_id/:onestop_id', to: 'onestop_id#show'
      resources :changesets, only: [:index, :show, :create, :update, :destroy] do
        member do
          post 'check'
          post 'apply'
          post 'revert'
        end
        resources :change_payloads, only: [:index, :show, :create, :update, :destroy]
      end
      resources :stops, only: [:index, :show]
      resources :operators, only: [:index, :show]
      resources :routes, only: [:index, :show]
      resources :route_stop_patterns, only: [:index, :show]
      resources :schedule_stop_pairs, only: [:index]
      resources :feeds, only: [:index, :show] do
        resources :feed_versions, only: [:index, :show, :update] do
          resources :feed_version_imports, only: [:index, :show]
        end
      end
      post '/feeds/fetch_info', to: 'feeds#fetch_info'
      post '/webhooks/feed_fetcher', to: 'webhooks#feed_fetcher'
      post '/webhooks/feed_eater', to: 'webhooks#feed_eater'
      # TODO: expose user authentication endpoints in the future
      # devise_for :users
      resources :users
    end
    match '*unmatched_route', :to => 'v1/base_api#raise_not_found!', via: :all
  end

  mount DatastoreAdmin::Engine => '/admin'
end
