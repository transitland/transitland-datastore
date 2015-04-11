unless Rails.env.test?
  Figaro.require_keys("API_AUTH_TOKENS")
end
