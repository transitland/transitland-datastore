require 'sidekiq/web'

if Rails.env.production? || Rails.env.staging?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == Figaro.env.admin_username && password == Figaro.env.admin_password
  end
  # PgHero auth is set in /config/initializers/pghero.rb
end

DatastoreAdmin::Engine.routes.draw do
  root to: 'dashboard#main'
  post '/reset', to: 'dashboard#reset'
  get '/dispatcher', to: 'dashboard#dispatcher', as: :dispatcher
  get '/sidekiq_dashboard', to: 'dashboard#sidekiq_dashboard', as: :sidekiq_dashboard
  get '/postgres_dashboard', to: 'dashboard#postgres_dashboard', as: :postgres_dashboard
  mount Sidekiq::Web, at: '/sidekiq'
  mount PgHero::Engine, at: '/postgres'
end
