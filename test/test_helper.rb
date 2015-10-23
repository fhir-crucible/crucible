ENV['RAILS_ENV'] ||= 'test'
require 'simplecov'
SimpleCov.start 'rails'
SimpleCov.at_exit do
  SimpleCov.result.format!
  system("open coverage/index.html")
end
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/autorun'
require 'pry'
require 'webmock/minitest'

class ActiveSupport::TestCase

  def dump_database
    Mongoid.default_session.collections.each do |c|
      c.drop() unless c.name == 'tests'
    end
  end

end
