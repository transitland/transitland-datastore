unless Rails.env.test?
  Figaro.require_keys("TRANSITLAND_DATASTORE_AUTH_TOKEN")
end
