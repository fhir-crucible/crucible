require File.expand_path('../boot', __FILE__)

# require 'rails/all'
require "action_controller/railtie"
require "action_mailer/railtie"
# require "active_resource/railtie" # Comment this line for Rails 4.0+
require "rails/test_unit/railtie"
require "sprockets/railtie" # Uncomment this line for Rails 3.1+
require "fhir_scorecard"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Crucible
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Bower asset paths
    Rails.root.join('vendor', 'assets', 'bower_components').to_s.tap do |bower_path|
      config.sass.load_paths << bower_path
      config.assets.paths << bower_path
    end
    
    HandlebarsAssets::Config.compiler_path = Rails.root.join('vendor/assets/bower_components/handlebars')

    # Precompile Bootstrap fonts
    config.assets.precompile << %r(bootstrap-sass/assets/fonts/bootstrap/[\w-]+\.(?:eot|svg|ttf|woff2?)$)
    # Precompile fontawsome fonts
    config.assets.precompile << %r(font-awesome/fonts/[\w-]+\.(?:eot|svg|ttf|woff2?)$)
    # Minimum Sass number precision required by bootstrap-sass
    #::Sass::Script::Value::Number.precision = [8, ::Sass::Script::Value::Number.precision].max

    config.autoload_paths << Rails.root.join('lib')

    config.active_job.queue_adapter = :delayed_job

    # Configuration to determine if Crucible restricts available ports to 443, 80, 8080
    # false: allow requests to all FHIR server ports
    # true: only allow requests to 443, 80, 8080
    config.restrict_test_ports = false

    # Configuration to show which version of crucible is the most recent and is being tested on this server
    config.fhir_sequence = 'STU3'
    config.fhir_version = '1.8.0'
    config.fhir_version_name = 'FHIR STU3 Candidate + Connectathon 14 (San Antonio)'

    # Configuration to determine if localhost servers and servers referencing localhost IP addresses are allowed (127.0.0.1)
    # false: allows localhost urls
    # true: rejects localhost urls to either localhost or localhost IP addresses
    config.restrict_localhost_urls = false

    FHIR::Terminology.set_terminology_root(Rails.root.join('terminology').to_s)

  end
end
