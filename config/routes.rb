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
    
      scope 'gtfs' do
        resources :agencies, controller: 'gtfs_agencies', only: [:index, :show]
        resources :calendar_dates, controller: 'gtfs_calendar_dates', only: [:index, :show]
        resources :calendars, controller: 'gtfs_calendars', only: [:index, :show]
        resources :fare_attributes, controller: 'gtfs_fare_attributes', only: [:index, :show]
        resources :fare_rules, controller: 'gtfs_fare_rules', only: [:index, :show]
        resources :feed_infos, controller: 'gtfs_feed_infos', only: [:index, :show]
        resources :frequencies, controller: 'gtfs_frequencies', only: [:index, :show]
        resources :routes, controller: 'gtfs_routes', only: [:index, :show]
        resources :shapes, controller: 'gtfs_shapes', only: [:index, :show]
        resources :stop_times, controller: 'gtfs_stop_times', only: [:index, :show]
        resources :transfers, controller: 'gtfs_transfers', only: [:index, :show]
        resources :trips, controller: 'gtfs_trips', only: [:index, :show]
        resources :stops, controller: 'gtfs_stops', only: [:index, :show]
      end

      resources :stops, only: [:index, :show] do
        member do
          get 'headways'
        end
      end


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
          get 'feed_version_update_statistics'
        end
        collection do
          post 'fetch_info'
        end
      end
      resources :feed_versions, only: [:index, :show, :create, :update]
      resources :feed_version_infos, only: [:index, :show]
      resources :feed_version_imports, only: [:index, :show]
      resources :issues, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get 'categories'
        end
      end
      post '/webhooks/feed_fetcher', to: 'webhooks#feed_fetcher'
      post '/webhooks/feed_eater', to: 'webhooks#feed_eater'

      # authentication using Devise gem and JWT auth tokens
      devise_for :users, :skip => :all
      post 'users/session', to: 'user_sessions#create'
      delete 'users/session', to: 'user_sessions#destroy'
      resources :users
    end

    match '*unmatched_route', :to => 'v1/base_api#raise_not_found!', via: :all
  end

  mount DatastoreAdmin::Engine => '/admin'
end
