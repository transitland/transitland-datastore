source 'https://rubygems.org'

gem 'rails', '4.2.0'

# configuration
gem 'figaro'

# web server
gem 'unicorn', group: [:staging, :production]

# data stores
gem 'pg'
gem 'activerecord-postgis-adapter', '3.0.0.beta2'
gem 'redis-rails'

# background processing
gem 'sidekiq'

# data model
gem 'squeel'
gem 'enumerize'
gem 'gtfs'
gem 'rgeo-geojson'
gem 'c_geohash', require: 'geohash'
gem 'json-schema'

# authentication and authorization
gem 'rack-cors', :require => 'rack/cors'
gem 'omniauth'
gem 'omniauth-osm'

# API
gem 'active_model_serializers', '0.9.3'
gem 'oj'

# views
gem 'slim'

# CSS
gem 'bootstrap-sass'
gem 'sass-rails-source-maps'

# JavaScript
gem 'coffee-rails'
gem 'coffee-rails-source-maps'
gem 'uglifier'
gem 'therubyracer', platforms: :ruby

# development tools
gem 'better_errors', group: :development
gem 'binding_of_caller', group: :development
gem 'byebug', group: [:development, :test]
gem 'pry-byebug', group: [:development, :test]
gem 'pry-rails', group: [:development, :test]

# code coverage and documentation
gem 'rails-erd', group: :development
gem 'annotate', group: :development, github: 'ctran/annotate_models', ref: '46dc084'
gem 'simplecov', :require => false, group: [:development, :test]

# testing
gem 'database_cleaner', group: :test
gem 'factory_girl_rails', group: [:development, :test]
gem 'ffaker', group: [:development, :test]
gem 'rspec-rails', group: [:development, :test]
gem 'airborne', group: :test
gem 'capybara', group: :test
gem 'selenium-webdriver', group: :test

# misc.
gem 'ruby-progressbar'
gem 'filesize'
