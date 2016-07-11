require 'simplecov'

if ENV['CIRCLE_ARTIFACTS']
  # if running on CircleCI, upload coverage report to codecov.io
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

SimpleCov.start do
  load_profile 'rails'

  add_group 'Services', 'app/services'
  add_group 'Serializers', 'app/serializers'
  add_group 'Workers', 'app/workers'

  # store SimpleCov reports on CircleCI as artifacts
  coverage_dir(File.join("..", "..", "..", ENV['CIRCLE_ARTIFACTS'], "coverage")) if ENV['CIRCLE_ARTIFACTS']
end

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'sidekiq/testing'
require 'database_cleaner'
require 'ffaker'
require 'byebug'
require 'vcr'
require 'webmock/rspec'
require 'factory_girl_rails'
require 'timecop'
Timecop.safe_mode = true

ActiveRecord::Migration.maintain_test_schema!

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

VCR.configure do |c|
  c.cassette_library_dir = File.join(File.dirname(__FILE__), '/support/vcr_cassettes')
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

RSpec::Sidekiq.configure do |config|
  config.warn_when_jobs_not_processed_by_sidekiq = false
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run_excluding :optional => true
  config.infer_spec_type_from_file_location!

  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation, { except: ['spatial_ref_sys'] }
    DatabaseCleaner.start
    clear_carrierwave_attachments
    Sidekiq::Worker.clear_all
  end

  config.before(:each) do
    DatabaseCleaner.clean_with :truncation, { except: ['spatial_ref_sys'] }
    Sidekiq::Worker.clear_all
  end

  config.after(:each) do
    clear_carrierwave_attachments
  end
end

# create directory used for local test cache
FileUtils.mkdir_p(Rails.root.join('tmp', 'cache'))

def clear_carrierwave_attachments
  FileUtils.rm_rf(Rails.root.join('public', 'uploads', 'test'))
end
