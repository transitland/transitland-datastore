Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/onestop_id/:onestop_id', to: 'onestop_id#show'
      resources :changesets, only: [:index, :show, :create] do
        member do
          post 'check'
          post 'apply'
          post 'revert'
        end
      end
      resources :stops, only: [:index, :show]
      resources :operators, only: [:index, :show]
    end
  end
end
