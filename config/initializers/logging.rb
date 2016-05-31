def log(msg)
  if Sidekiq::Logging.logger
    Sidekiq::Logging.logger.info msg
  elsif Rails.logger
    Rails.logger.info msg
  else
    puts msg
  end
end
