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
    # TODO: Fix issue where default_session.collections is empty on certain machines
    # Mongoid.default_session.collections.each do |c|
    #   c.drop() unless c.name == 'tests'
    # end
    [AggregateRun, Server, SmartClient, SmartRun, Statistics, Summary, TestResult, TestRun].each {|m| m.delete_all}
  end

  def collection_fixtures(*collection_names)
    collection_names.each do |collection|
      Mongoid.default_session[collection].drop
      Dir.glob(File.join(Rails.root, 'test', 'fixtures', 'json', collection, '*.json')).each do |json_fixture_file|
        fixture_json = JSON.parse(File.read(json_fixture_file))
        fixture_json = [fixture_json] unless fixture_json.is_a? Array

        fixture_json.each do |fixture|
          set_mongoid_ids(fixture)
          Mongoid.default_session[collection].insert(fixture)
        end
      end
    end
  end

  def set_mongoid_ids(json)
    if json.kind_of?( Hash)
      json.each_pair do |k,v|
        if v && v.kind_of?( Hash )
          if v["$oid"]
            json[k] = BSON::ObjectId.from_string(v["$oid"])
          else
            set_mongoid_ids(v)
          end
        end
      end
    end
  end

end
