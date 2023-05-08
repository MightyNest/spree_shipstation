# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_shipstation'
  s.version     = '3.3.2'
  s.summary     = 'Spree/ShipStation Integration'
  s.description = 'Integrates ShipStation API with Spree. Supports exporting shipments and importing tracking numbers'
  s.required_ruby_version = '>= 2.0.0'

  s.author    = 'Dmitry Kosenko'
  s.email     = 'kosenkodmitryv@gmail.com'
  s.homepage  = 'https://github.com/KosenkoDmitriy/spree_shipstation'

  s.require_path = 'lib'
  s.requirements << 'none'

  spree_version = '>= 3.1.0', '< 4.0'
  s.add_dependency 'spree_core', spree_version

  s.add_development_dependency 'capybara', '~> 2.4'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.5'
  s.add_development_dependency 'ffaker', '~> 2.2'
  s.add_development_dependency 'rspec-rails',  '~> 3.1'
  s.add_development_dependency 'sass-rails', '~> 5.0.0.beta1'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end
