Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :stops, except: [:new] do
        resources :stop_identifiers, except: [:new]
      end
    end
  end
end
