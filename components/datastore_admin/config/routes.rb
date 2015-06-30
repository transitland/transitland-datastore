require 'sidekiq/web'

if Rails.env.production? || Rails.env.staging?
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == Figaro.env.admin_username && password == Figaro.env.admin_password
  end
end

DatastoreAdmin::Engine.routes.draw do
  root to: 'dashboard#main'
  post '/reset', to: 'dashboard#reset'
  mount Sidekiq::Web => '/workers'
end
