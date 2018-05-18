require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TransitlandDatastore
  class Application < Rails::Application
    def self.base_url_options
      if Figaro.env.transitland_datastore_host.present?
        base_url_options = {
          host: Figaro.env.transitland_datastore_host.match(/:\/\/([^:]+)/)[1],
          protocol: Figaro.env.transitland_datastore_host.split('://')[0],
          port: nil
        }
        if (port_match = Figaro.env.transitland_datastore_host.match(/:(\d+)/))
          base_url_options[:port] = port_match[1]
        end
      else
        base_url_options = {
          host: 'localhost',
          protocol: 'http',
          port: '3000'
        }
      end
      base_url_options
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
      end
    end

    # Load protobuf definitions
    Dir["#{Rails.root}/lib/proto/*.rb"].each { |file| require file }

    config.assets.enabled = false

    # https://github.com/carrierwaveuploader/carrierwave/issues/1576
    config.active_record.raise_in_transactional_callbacks = true

    # e-mail
    config.action_mailer.default_url_options = base_url_options
    if Rails.env.development?
      # Send mail to mailcatcher gem
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = {
        address: "localhost",
        port: 1025
      }
      config.action_mailer.raise_delivery_errors = false
    elsif Rails.env.test?
      # Tell Action Mailer not to deliver emails to the real world.
      # The :test delivery method accumulates sent emails in the
      # ActionMailer::Base.deliveries array.
      config.action_mailer.delivery_method = :test
    elsif Rails.env.staging? || Rails.env.production?
      # Ignore bad email addresses and do not raise email delivery errors.
      # Set this to true and configure the email server for immediate delivery to raise delivery errors.
      config.action_mailer.raise_delivery_errors = false

      config.action_mailer.smtp_settings = {
          address: Figaro.env.smtp_address,
          port: Figaro.env.smtp_port.presence.to_i || 587,
          enable_starttls_auto: true,
          user_name: Figaro.env.smtp_user_name,
          password: Figaro.env.smtp_password,
          authentication: :plain,
          domain: 'transitland.org'
        }
    end
  end
end
