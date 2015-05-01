source 'https://rubygems.org'

gem 'rails', '4.2.0'

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

# Onestop libraries
gem 'onestop-id-client', github: 'transitland/onestop-id-ruby-client', tag: 'v0.0.4', require: 'onestop_id_client'
gem 'onestop-id-registry-validator', github: 'transitland/onestop-id-registry-validator', tag: 'v0.0.4', require: 'onestop_id_registry_validator'

# authentication and authorization
gem 'rack-cors', :require => 'rack/cors'
gem 'omniauth'
gem 'omniauth-osm'

# API
gem 'active_model_serializers', '0.9.3'
gem 'oj'

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
gem 'airborne', group: :test

# deployment and monitoring
gem 'aws-sdk', group: [:staging, :production]
gem 'newrelic_rpm', group: [:staging, :production]
gem 'bullet', group: :development
gem 'skylight', group: [:staging, :production]

# web server
gem 'unicorn', group: [:staging, :production]
