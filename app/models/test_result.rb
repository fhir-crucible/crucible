class TestResult
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :test
  belongs_to :test_run
  belongs_to :server
  field :has_run, type: Boolean, default: false
  field :result
  field :setup_requests
  field :teardown_requests

  def reissue_request(test_id, request_index)
    client = FHIR::Client.new(self.server.url)
    client.default_format = self.server.default_format if self.server.default_format
    if test_id == "setup" || test_id == "teardown"
      request = self["#{test_id}_requests"][request_index]['request']
    else
      request = self.result.find{|t| t['id'] == test_id}['requests'][request_index]['request']
    end

    client.reissue_request(request)

  end

end
