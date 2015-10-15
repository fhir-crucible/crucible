$(window).on('load', ->
  new Crucible.TestExecutor()
)

class Crucible.TestExecutor
  suites: []
  suitesById: {}
  templates:
    suiteSelect: 'views/templates/servers/suite_select'
    suiteResult: 'views/templates/servers/suite_result'
    testResult: 'views/templates/servers/partials/test_result'
  html:
    selectAllButton: '<i class="fa fa-check"></i>&nbsp;Deselect All Test Suites'
    deselectAllButton: '<i class="fa fa-check"></i>&nbsp;Select All Test Suites'
    collapseAllButton: '<i class="fa fa-expand"></i>&nbsp;Collapse All Test Suites'
    expandAllButton: '<i class="fa fa-expand"></i>&nbsp;Expand All Test Suites'
    spinner: '<span class="fa fa-lg fa-fw fa-spinner fa-pulse tests"></span>'
  statusWeights: {'pass': 1, 'skip': 2, 'fail': 3, 'error': 4}

  constructor: ->
    @element = $('.test-executor')
    return unless @element.length
    @element.data('testExecutor', this)
    @serverId = @element.data('server-id')
    @progress = $("##{@element.data('progress')}")
    @registerHandlers()
    @loadTests()

  registerHandlers: =>
    @element.find('.execute').click(@execute)
    @element.find('.selectDeselectAll').click(@selectDeselectAll)
    @element.find('.expandCollapseAll').click(@expandCollapseAll)
    @element.find('.filter-by-executed a').click(@showAllSuites)
    @filterBox = @element.find('.test-results-filter')
    @filterBox.on('keyup', @filter)

  loadTests: =>
    $.getJSON("/tests.json").success((data) =>
      @suites = data['tests']
      @renderSuites()
      @element.trigger('testsLoaded')
    )

  renderSuites: =>
    suitesElement = @element.find('.test-suites')
    suitesElement.empty()
    $(@suites).each (i, suite) =>
      @suitesById[suite.id] = suite
      suitesElement.append(HandlebarsTemplates[@templates.suiteSelect]({suite: suite}))
      suiteElement = suitesElement.find("#test-#{suite.id}")
      suiteElement.data('suite', suite)
      $(suite.methods).each (i, test) =>
        @addClickTestHandler(test, suiteElement)

  selectDeselectAll: =>
    suiteElements = @element.find('.test-run-result :visible :checkbox')
    button = $('.selectDeselectAll')
    if !$(suiteElements).prop('checked')
      $(suiteElements).prop('checked', true)
      $(button).html(@html.selectAllButton)
    else
      $(suiteElements).prop('checked', false)
      $(button).html(@html.deselectAllButton)

  expandCollapseAll: =>
    suiteElements = @element.find('.test-run-result .collapse')
    button = $('.expandCollapseAll')
    if !$(suiteElements).hasClass('in')
      $(suiteElements).collapse('show')
      $(button).html(@html.collapseAllButton)
    else
      $(suiteElements).collapse('hide')
      $(button).html(@html.expandAllButton)

  execute: =>
    suiteIds = $($.map(@element.find(':checked'), (e) -> e.name))
    if suiteIds.length > 0
      @element.find('.execute').addClass('disabled')
      @showOnlyExecutedSuites()
      @progress.parent().collapse('show')
      @progress.find('.progress-bar').css('width',"2%")
      @element.queue("executionQueue", this.registerTestRun)
      suiteIds.each (i, suiteId) =>
        suiteElement = @element.find("#test-#{suiteId}")
        suiteElement.find('.test-status').empty().append(@html.spinner)
        @element.queue("executionQueue", =>
          $.post("/servers/#{@serverId}/testruns/#{@testRunId}/execute",{test_ids: [suiteId], finish: 0}
          ).success((result) =>
           if result.success
             @processTestResult(i, suiteId, suiteIds, result.test_results[0], suiteElement)
           else
             @processTestResult(i, suiteId, suiteIds, @createErrorSuite(suiteId), suiteElement)
          ).error(=>
            @processTestResult(i, suiteId, suiteIds, @createErrorSuite(suiteId), suiteElement)
          )
        )
      @element.queue("executionQueue", this.regenerateSummary)
      @element.dequeue("executionQueue")
    else 
      @flashWarning('Please select at least one test suite')

  processTestResult: (i, suiteId, suiteIds, result, suiteElement) ->
    @progress.find('.progress-bar').css('width',"#{(i+1)/suiteIds.length*100}%")
    @handleSuiteResult(@suitesById[suiteId], result, suiteElement)
    if i < suiteIds.length-1
      @element.dequeue("executionQueue")
    else
      @progress.parent().collapse('hide')
      @progress.find('.progress-bar').css('width',"0%")
      @element.find('.execute').removeClass('disabled')
      @element.dequeue("executionQueue")

  handleSuiteResult: (suite, result, suiteElement) =>
    suiteStatus = 'pass'
    result.tests = result.result
    $(result.tests).each (i, test) =>
      suiteStatus = test.status if @statusWeights[suiteStatus] < @statusWeights[test.status]
    result.suiteStatus = suiteStatus

    suiteElement.replaceWith(HandlebarsTemplates[@templates.suiteResult]({suite: suite, result: result}))
    suiteElement = @element.find("#test-"+suite.id)
    suiteElement.data('suite', suite)
    $(result.tests).each (i, test) =>
      @addClickTestHandler(test, suiteElement)

  filter: =>
    filterValue = @filterBox.val().toLowerCase()
    elements = @element.find('.test-run-result')
    if (filterValue.length == 0)
      elements.show()
      return
    $(elements).each (i, suiteElement) =>
      suiteElement = $(suiteElement)
      suite = suiteElement.data('suite')
      if (suite.name.toLowerCase()).indexOf(filterValue) < 0
        suiteElement.hide()
      else
        suiteElement.show()
        
  showAllSuites: =>
    @element.find('.filter-by-executed').collapse('hide')
    @element.find('.test-run-result').show()

  showOnlyExecutedSuites: =>
    @element.find('.filter-by-executed').collapse('show')
    @element.find('.test-run-result').hide()
    @element.find(':checked').closest('.test-run-result').show()
    @element.find('.test-run-result.executed').show()
  
  registerTestRun: =>
    $.post("/servers/#{@serverId}/testruns.json", {test_run: {server_id: @serverId}}).success((result) =>
      @testRunId = result.test_run.id
      @element.dequeue("executionQueue")
    )

  flashWarning: (message) =>
    warningBanner = @element.find('.warning-message')
    $(warningBanner).html(message)
    $(warningBanner).fadeIn()
    $(warningBanner).delay(1000).fadeOut(1500)

  regenerateSummary: =>
    $.post("/servers/#{@serverId}/testruns/#{@testRunId}/finish").success((result) =>
      new Crucible.Summary()
      new Crucible.TestRunReport()
      @element.dequeue("executionQueue")
    )

  addClickTestHandler: (test, suiteElement) => 
    handle = suiteElement.find(".suite-handle[data-key='#{test.key}']")
    handle.click =>
      suiteElement.find(".suite-handle").removeClass('active')
      handle.addClass('active')
      suiteElement.find('.test-results').empty().append(HandlebarsTemplates[@templates.testResult]({test: test}))
      suiteElement.find(".data-link").click (e) -> 
        $('#data-modal .modal-body').empty().append($(e.target).parent().find('.data-content').html())
        hljs.highlightBlock($('#data-modal .modal-body')[0]);


  createErrorSuite: (suiteId) ->
    suite = _.clone(@suitesById[suiteId])
    suite.tests = suite.methods
    for test in suite.tests
      test.status = 'error'
      test.message = 'The test could not be executed'
    suite

