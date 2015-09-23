stored_tests = Test.all.to_a.map {|t| t.name}
executor = Crucible::Tests::Executor.new(nil)

( Crucible::Tests::Executor.list_all(true).merge( Crucible::Tests::Executor.list_all ) ).each do |key,value|
  unless stored_tests.include?(key.to_s)
    test = Test.new
    test.name = key.to_s
    test.title = value["title"]
    test.author = value["author"]
    test.description = value["description"]

    crucibleTest = executor.find_test(value['title'])
    if value["resource_class"]
      test.resource_class = value["resource_class"].to_s
      crucibleTest.resource_class = value["resource_class"]
    end
    test.multiserver = value["multiserver"]

    metadata = crucibleTest.collect_metadata.first

    test.methods = metadata.values.first[:tests].map do |method|
      method.except('data','code', 'status', 'message')
    end

    test.save()

  end

end
