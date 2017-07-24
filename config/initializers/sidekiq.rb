# We still use the Delayed extensions to send e-mail notifications.
# See: https://github.com/mperham/sidekiq/blob/master/5.0-Upgrade.md#whats-new

Sidekiq::Extensions.enable_delay!
