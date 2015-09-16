class TestResult
  include Mongoid::Document
  belongs_to :test
  belongs_to :test_run
  field :has_run, type: Boolean, default: false
  field :result

  def execute(executor=nil)

    unless executor
      client1 = FHIR::Client.new(self.test_run.server.url)
      client2 = FHIR::Client.new(self.test_run.destination_server.url) if self.test_run.is_multiserver
      executor = Crucible::Tests::Executor.new(client1, client2)
    end

    crucible_test = executor.find_test(self.test.title)
    crucible_test.conformance = self.test_run.server.raw_conformance if crucible_test.respond_to? :conformance=

    val = nil
    if self.test.resource_class?
      val = crucible_test.execute(self.test.resource_class.constantize)[0]["#{self.test.title}_#{self.test.resource_class.split("::")[1]}"][:tests]
    else
      val = crucible_test.execute()[0][self.test.title][:tests]
    end

    self.has_run = true
    self.result = val
  end
end
