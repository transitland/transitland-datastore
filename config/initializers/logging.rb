def log(msg, level = :info)
  msg = msg.to_s
  if Sidekiq::Logging.logger
    Sidekiq::Logging.logger.send level, msg
  elsif Rails.logger
    Rails.logger.send level, msg
  else
    puts msg
  end
end
