#= require application
#= require views/component/test-executor

describe "test-executor", ->

  # beforeEach( ->
  #   fixture.set("<div class='test-executor'></div>");
  # )

  beforeEach( ->
    MagicLamp.load("servers/show");
    @executor = new Crucible.TestExecutor()
  )

  it "should load tests", (done) ->
    expect(@executor.element).not.toBe(null)

    @executor.loadTests().done(=> 
      tests = @executor.element.find('.test-suites').children()
      expect(tests.length).toBeGreaterThan(0)
      console.log("loaded #{tests.length} tests")
      done()
    )

  it "should select all", (done) ->
    element = @executor.element

    @executor.loadTests().done(=> 
      checkboxes = element.find('.test-run-result :visible')
      count = checkboxes.find(':checkbox').length

      countSelected = checkboxes.find(":checked").length
      expect(countSelected).toBe(0)

      @executor.selectDeselectAll()

      countSelected = checkboxes.find(":checked").length
      expect(countSelected).toBe(count)

      @executor.selectDeselectAll()

      countSelected = checkboxes.find(":checked").length
      expect(countSelected).toBe(0)

      done()
    )
