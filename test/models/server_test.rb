require_relative '../test_helper'

class ServerTest < ActiveSupport::TestCase

  def setup
    @conformance_xml = File.read(Rails.root.join('test','fixtures','xml','conformance', 'bonfire_conformance.xml'))
  end

  def test_load_conformance
    server = Server.new ({url: 'www.example.com'})

    assert_nil server.conformance

    stub = stub_request(:get, "www.example.com/metadata").to_return(:body => @conformance_xml)
    stub.times(1)

    conformance = server.load_conformance

    assert_not_nil conformance['rest']
    assert_not_nil server.conformance

    # will fail if we request again
    conformance = server.load_conformance

  end

end