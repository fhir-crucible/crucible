class TestResult
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :test
  belongs_to :test_run
  belongs_to :server
  field :has_run, type: Boolean, default: false
  field :result

  def reissue_request(test_id, request_index)
    client = FHIR::Client.new(self.server.url)
    client.default_format = self.server.default_format if self.server.default_format
    request = self.result.find{|t| t['id'] == test_id}['requests'][request_index]['request']

    client.reissue_request(request)

  end

end
