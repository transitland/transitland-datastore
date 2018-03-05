# We still use the Delayed extensions to send e-mail notifications.
# See: https://github.com/mperham/sidekiq/blob/master/5.0-Upgrade.md#whats-new
Sidekiq::Extensions.enable_delay!

# Sidekiq-cron
schedule_file = Rails.root.join('config', 'schedule.yml')
if File.exists?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end
