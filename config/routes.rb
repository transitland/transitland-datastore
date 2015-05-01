require 'sidekiq/web'

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  username == Figaro.env.sidekiq_dashboard_username && password == Figaro.env.sidekiq_dashboard_password
end if Rails.env.production?

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/onestop_id/:onestop_id', to: 'onestop_id#show'
      resources :changesets, only: [:index, :show, :create, :update] do
        member do
          post 'check'
          post 'apply'
          post 'revert'
        end
      end
      resources :stops, only: [:index, :show]
      resources :operators, only: [:index, :show]
      resources :routes, only: [:index, :show]
      post '/webhooks/feed_eater', to: 'webhooks#feed_eater'
    end
    match '*unmatched_route', :to => 'v1/base_api#raise_not_found!', via: :all
  end

  mount Sidekiq::Web => '/worker_dashboard'
end
