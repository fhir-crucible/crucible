source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.4'

# 'respond_to' has been extracted to a gem
gem 'responders', '~> 2.0'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# these are now included automatically in plan_executor
# gem 'fhir_models', :git => 'https://github.com/fhir-crucible/fhir_models.git'
# gem 'fhir_client', :git => 'https://github.com/fhir-crucible/fhir_client.git'

gem 'plan_executor', :git => 'https://github.com/fhir-crucible/plan_executor.git', :branch => 'r4'
# gem 'plan_executor', :path => '../plan_executor'
gem 'fhir_scorecard', :git => 'https://github.com/fhir-crucible/fhir_scorecard.git'
#gem 'fhir_scorecard', :path => '../fhir_scorecard'
gem 'synthea', :git => 'https://github.com/synthetichealth/synthea.git', :branch => 'ruby'
#gem 'synthea', :path => '../synthea'

gem 'mongoid', '>= 4.0.0', '< 5' # lock mongoid below 5 for the moment, as it requires code changes
# gem 'autoprefixer-rails'
gem 'nokogiri'
gem 'date_time_precision'
gem 'rest-client'
gem 'mongoid-history'
gem 'active_model_serializers'
gem 'pry'
gem 'bcp47'
gem 'nokogiri-diff'
gem 'addressable'
gem 'handlebars_assets', '0.16' # pin to 0.16 for now as 0.17 introduces breaking changes
gem 'oauth2'
gem 'ruby-progressbar'
gem "non-stupid-digest-assets"
gem 'delayed_job_mongoid'
gem 'daemons'
gem 'time_difference'
gem 'mongo_session_store-rails4'

group :development, :test do
  gem 'pry-byebug'
  gem 'guard-livereload'
  gem "teaspoon-jasmine"
  gem "magic_lamp"
end

group :test do
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'simplecov', require: false
  gem 'webmock'
end
