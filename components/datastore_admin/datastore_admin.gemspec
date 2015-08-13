$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'datastore_admin/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'datastore_admin'
  s.version     = DatastoreAdmin::VERSION
  s.authors     = ['Drew Dara-Abrams']
  s.email       = ['drew@mapzen.com']
  s.homepage    = 'https://github.com/transitland/transitland-datastore'
  s.summary     = 'Admin interface for the Transitland Datastore.'
  s.description = 'Admin interface for the Transitland Datastore, wrapped as a Rails engine.
                   Keeps HTML-generating views out of the core of the Datastore, which is
                   focused on serving a JSON API.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']

  s.add_dependency 'sinatra' # for Sidekiq dashboard
end
