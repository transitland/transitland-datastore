if Rails.env.production? || Rails.env.staging?
  ENV["PGHERO_USERNAME"] = Figaro.env.admin_username
  ENV["PGHERO_PASSWORD"] = Figaro.env.admin_password
end
