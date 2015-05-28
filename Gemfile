source 'https://rubygems.org'

gem 'rails', '4.2.1'

# process runner
gem 'foreman', group: :development

# configuration
gem 'figaro'

# data stores
gem 'pg'
gem 'activerecord-postgis-adapter', '3.0.0.beta4'
gem 'redis-rails'

# background processing
gem 'sidekiq'
gem 'sinatra', require: nil # for Sidekiq dashboard
gem 'whenever', require: false # to manage crontab

# data model
gem 'squeel'
gem 'enumerize'
gem 'gtfs'
gem 'rgeo-geojson'
gem 'c_geohash', require: 'geohash'
gem 'json-schema'

# Transitland libraries
gem 'transitland_client', github: 'transitland/transitland-ruby-client', tag: 'v0.0.5', require: 'transitland_client'

# authentication and authorization
gem 'rack-cors', require: 'rack/cors'
gem 'omniauth'
gem 'omniauth-osm'

# providing API
gem 'active_model_serializers', '0.9.3'
gem 'oj'

# consuming other APIs
gem 'faraday'

# development tools
gem 'better_errors', group: :development
gem 'binding_of_caller', group: :development
gem 'byebug', group: [:development, :test]
gem 'pry-byebug', group: [:development, :test]
gem 'pry-rails', group: [:development, :test]

# code coverage and documentation
gem 'rails-erd', group: :development
gem 'annotate', group: :development
gem 'simplecov', :require => false, group: [:development, :test]

# testing
gem 'database_cleaner', group: :test
gem 'factory_girl_rails', group: [:development, :test]
gem 'ffaker', group: [:development, :test]
gem 'rspec-rails', group: [:development, :test]
gem 'vcr', group: :test
gem 'webmock', group: :test
gem 'airborne', group: :test

# deployment and monitoring
gem 'aws-sdk', group: [:staging, :production]
gem 'sentry-raven', group: [:staging, :production]
gem 'bullet', group: :development

# web server
gem 'unicorn', group: [:staging, :production]
