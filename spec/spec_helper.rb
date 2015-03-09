require 'simplecov'
SimpleCov.start do
  load_profile 'rails'

  add_group 'Services', 'app/services'
  add_group 'Serializers', 'app/serializers'

  coverage_dir(File.join("..", "..", "..", ENV['CIRCLE_ARTIFACTS'], "coverage")) if ENV['CIRCLE_ARTIFACTS']
end

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'database_cleaner'
require 'ffaker'
require 'byebug'

ActiveRecord::Migration.maintain_test_schema!

Capybara.app_host = "http://localhost:3030"
Capybara.server_port = 3030
# Note that this port is on the Sauce Connect list of ports to proxy by default
# https://docs.saucelabs.com/reference/sauce-connect/#can-i-access-applications-on-localhost-

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec

  config.infer_spec_type_from_file_location!

  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation, { except: ['spatial_ref_sys'] }
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean_with :truncation, { except: ['spatial_ref_sys'] }
    end
  end

  config.before(:each) do
    # TODO: sign out current user
    DatabaseCleaner.clean_with :truncation, { except: ['spatial_ref_sys'] }
  end

  config.before(:each, type: :feature) do
    Capybara.reset!
  end
end
