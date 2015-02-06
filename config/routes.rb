Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/onestop_id/:onestop_id', to: 'onestop_id#show'
      resources :stops, only: [:index, :show]
      resources :operators, only: [:index, :show]
    end
  end
end
