class DatastoreAdmin::ApplicationController < ActionController::Base
  if Rails.env.production? || Rails.env.staging?
    http_basic_authenticate_with name: Figaro.env.admin_username, password: Figaro.env.admin_password
  end
end
