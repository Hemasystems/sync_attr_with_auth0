Gem::Specification.new do |gem|
  gem.name          = 'sync_attr_with_auth0'
  gem.version       = '0.2.9'
  gem.date          = '2016-07-26'
  gem.summary       = "Synchronize attributes on a local ActiveRecord user model with the user metadata store on Auth0"
  gem.description   = gem.summary
  gem.authors       = ["Patrick McGraw", "Mike Oliver", "Eric Anderson"]
  gem.email         = 'patrick@mcgraw-tech.com'
  gem.files         = [
    "lib/sync_attr_with_auth0.rb",
    "lib/sync_attr_with_auth0/auth0.rb",
    "lib/sync_attr_with_auth0/configuration.rb",
    "lib/sync_attr_with_auth0/adapters/active_record.rb",
    "lib/sync_attr_with_auth0/adapters/active_record/auth0_sync.rb",
    "lib/sync_attr_with_auth0/adapters/active_record/validation.rb"
  ]
  gem.homepage      = 'http://rubygems.org/gems/sync_attr_with_auth0'
  gem.license       = 'MIT'
  gem.require_paths = ['lib']

  gem.add_dependency 'rest-client', '>= 1.7'
  gem.add_dependency 'json'
  gem.add_dependency 'activerecord', '>= 4.0.0'
  gem.add_dependency 'activesupport', '>= 4.0.0'
  gem.add_dependency 'uuidtools'
  gem.add_dependency 'auth0', '>= 5.0.0'
  gem.add_dependency 'jwt', '>= 2.2.0'

  gem.add_development_dependency 'rails', '>= 4.0.0'
  gem.add_development_dependency 'rspec-rails'

end
