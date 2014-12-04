Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :stops, except: [:new]
      resources :operators, only: [:index, :show]
    end
  end
end
