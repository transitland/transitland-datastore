Rails.application.routes.default_url_options = TransitlandDatastore::Application.base_url_options

Rails.application.routes.draw do
  namespace :api do
    get '/', to: 'api#index'
    namespace :v1 do
      get '/', to: 'api_v1#index'
      get '/onestop_id/:onestop_id', to: 'onestop_id#show'
      get '/activity_updates', to: 'activity_updates#index'
      resources :changesets, only: [:index, :show, :create, :update, :destroy] do
        member do
          post 'check'
          post 'apply'
          post 'apply_async'
          post 'revert'
        end
        resources :change_payloads, only: [:index, :show, :create, :update, :destroy]
      end
      resources :stops, only: [:index, :show]
      resources :stop_stations, only: [:index, :show]
      resources :operators, only: [:index, :show] do
        collection do
          get 'aggregate'
        end
      end
      resources :routes, only: [:index, :show]
      resources :route_stop_patterns, only: [:index, :show]
      resources :schedule_stop_pairs, only: [:index]
      resources :feeds, only: [:index, :show] do
        member do
          get 'download_latest_feed_version'
        end
      end
      resources :feed_versions, only: [:index, :show, :update]
      resources :feed_version_imports, only: [:index, :show]
      resources :issues, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get 'categories'
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
