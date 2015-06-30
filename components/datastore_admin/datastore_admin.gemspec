$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'datastore_admin/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'datastore_admin'
  s.version     = DatastoreAdmin::VERSION
  s.authors     = ['Drew Dara-Abrams']
  s.email       = ['drew@mapzen.com']
  s.homepage    = 'TODO'
  s.summary     = 'TODO: Summary of DatastoreAdmin.'
  s.description = 'TODO: Description of DatastoreAdmin.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']

  s.add_dependency 'sass-rails'
  s.add_dependency 'bootstrap-sass', '~> 3.3'
  s.add_dependency 'sinatra' # for Sidekiq dashboard
end
