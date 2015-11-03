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
    unavailableError: '<div class="alert alert-danger"><strong>Error: </strong> Server Unavailable</div>'
    genericError: '<div class="alert alert-danger"><strong>Error: </strong> Tests could not be executed</div>'
  statusWeights: {'pass': 1, 'skip': 2, 'fail': 3, 'error': 4}
  checkStatusTimeout: 4000
  processedResults: {}

  constructor: ->
    @element = $('.test-executor')
    return unless @element.length
    @element.data('testExecutor', this)
    @serverId = @element.data('server-id')
    @testRunId = @element.data('current-test-run-id')
    @progress = $("##{@element.data('progress')}")
    @registerHandlers()
    @loadTests()

  registerHandlers: =>
    @element.find('.execute').click(@startTestRun)
    @element.find('.selectDeselectAll').click(@selectDeselectAll)
    @element.find('.expandCollapseAll').click(@expandCollapseAll)
    @element.find('.filter-by-executed a').click(@showAllSuites)
    @element.find('.past-test-runs-selector').change(@updateCurrentTestRun)
    @filterBox = @element.find('.test-results-filter')
    @filterBox.on('keyup', @filter)
    @element.find('.starburst').on('starburstInitialized', (event) =>
      @starburst = @element.find('.starburst').data('starburst')
      @starburst.addListener(this)
      false
    )

  loadTests: =>
    $.getJSON("/tests.json").success((data) =>
      @suites = data['tests']
      @renderSuites()
      @continueTestRun() if @testRunId
      @renderPastTestRunsSelector({text: 'Select past test run', value: '', disabled: true})
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

  renderPastTestRunsSelector: (elementToAdd) =>
    $.getJSON("/servers/#{@serverId}/past_runs").success((data) =>
      return unless data
      selector = @element.find('.past-test-runs-selector')
      selector.empty()
      if elementToAdd
        selector.append("<option value='#{elementToAdd.value}' disabled='#{elementToAdd.disabled}''>#{elementToAdd.text}</option>")
      selector.show()
      $(data['past_runs'].reverse()).each (i, test_run) =>
        selection = "<option value='#{test_run.id}'> #{moment(test_run.date).fromNow()} </option>"
        selector.append(selection)
    )

  updateCurrentTestRun: =>
    selector = @element.find('.past-test-runs-selector')
    testRunId = selector.val()
    suiteIds = $($.map(selector.find('option'), (e) -> e.value))
    $.getJSON("/servers/#{@serverId}/testruns/#{testRunId}").success((data) =>
      return unless data
      @renderSuites()
      @showOnlyExecutedSuites()
      $(data['test_run'].test_results).each (i, result) =>
        suiteId = result.test_id.$oid
        suiteElement = @element.find("#test-#{suiteId}")
        @handleSuiteResult(@suitesById[suiteId], {tests: result.result}, suiteElement)
    )

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

  prepareTestRun: (suiteIds) =>
    @processedResults = {}
    @element.find('.execute').addClass('disabled')
    @resetSuitePanels()
    @showOnlyExecutingSuites()
    @progress.parent().collapse('show')
    @progress.find('.progress-bar').css('width',"2%")
    @element.queue("executionQueue", @checkTestRunStatus)
    @element.queue("executionQueue", @finishTestRun)
    suiteIds.each (i, suiteId) =>
      suiteElement = @element.find("#test-#{suiteId}")
      suiteElement.find("input[type=checkbox]").attr("checked", true)
      suiteElement.find('.test-status').empty().append(@html.spinner)
    @showOnlyExecutedSuites()

  continueTestRun: =>
    $.get("/servers/#{@serverId}/testruns/#{@testRunId}").success((result) =>
      @prepareTestRun($($.map((result.test_run.test_ids), (e) -> e.$oid)))
      @element.dequeue("executionQueue")
      @element.find('.past-test-runs-selector').attr("disabled", true)
      @renderPastTestRunsSelector({text: 'Test in progress...', value: '', disabled: true})
    )

  startTestRun: =>
    suiteIds = $($.map(@element.find(':checked'), (e) -> e.name))
    @element.find(".test-result-error").empty()
    if suiteIds.length > 0
      @element.queue("executionQueue", @registerTestRun)
      @prepareTestRun(suiteIds)
      @element.dequeue("executionQueue")
    else 
      @flashWarning('Please select at least one test suite')

  registerTestRun: =>
    suiteIds = $.map(@element.find(':checked'), (e) -> e.name)
    $.post("/servers/#{@serverId}/testruns.json", { test_ids: suiteIds }).success((result) =>
      @testRunId = result.test_run.id
      @element.dequeue("executionQueue")
      @element.find('.past-test-runs-selector').attr("disabled", true)
      @renderPastTestRunsSelector({text: 'Test in progress...', value: '', disabled: true})
    )

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
    @renderPastTestRunsSelector({text: 'Select past test run', value: '', disabled: true})
    @element.find('.test-run-result').show()

  showOnlyExecutedSuites: =>
    @element.find('.filter-by-executed').collapse('show')
    @element.find('.test-run-result').hide()
    @element.find(':checked').closest('.test-run-result').show()
    @element.find('.test-run-result.executed').show()
  
  showOnlyExecutingSuites: =>
    @element.find('.filter-by-executed').collapse('show')
    @element.find('.test-run-result').hide()
    @element.find(':checked').filter('.suiteCheckbox').closest('.test-run-result').show()

  resetSuitePanels: =>
    suitesElement = @element.find('.test-suites')
    panels = @element.find('.test-run-result.executed')
    $(panels).each (i, panel) =>
      suite_id = (panel.id).substr(5)
      suite = @suitesById[suite_id]
      newPanel = HandlebarsTemplates[@templates.suiteSelect]({suite: suite})
      $(panel).replaceWith(newPanel)
      newElement = suitesElement.find("#test-#{suite.id}")
      newElement.data('suite', suite)
      $(suite.methods).each (i, test) =>
        @addClickTestHandler(test, newElement)

  checkTestRunStatus: =>
    suiteIds = $.map(@element.find(':checked'), (e) -> e.name)
    $.get("/servers/#{@serverId}/testruns/#{@testRunId}").success((result) =>
      test_run = result.test_run
      percent_complete = test_run.test_results.length / test_run.test_ids.length
      @progress.find('.progress-bar').css('width',"#{(Math.max(2, percent_complete * 100))}%")
      if Object.keys(@processedResults).length < test_run.test_results.length
        for result in test_run.test_results
          suiteId = result.test_id.$oid
          suite = @suitesById[suiteId]
          suiteElement = $("#test-#{suiteId}")
          @handleSuiteResult(suite, result, suiteElement) unless @processedResults[suiteId]
          @processedResults[suiteId] = true
      if test_run.status == "unavailable"
        @handleError(@html.unavailableError)
      else if test_run.status == "error"
        @handleError(@html.genericError)
      else if test_run.status == "finished"
        @element.dequeue("executionQueue")
      else
        setTimeout(@checkTestRunStatus, @checkStatusTimeout)
    )

  handleSuiteResult: (suite, result, suiteElement) =>
    suiteStatus = 'pass'
    if result.result
      result.tests = result.result
    $(result.tests).each (i, test) =>
      suiteStatus = test.status if @statusWeights[suiteStatus] < @statusWeights[test.status]
    result.suiteStatus = suiteStatus

    suiteElement.replaceWith(HandlebarsTemplates[@templates.suiteResult]({suite: suite, result: result}))
    suiteElement = @element.find("#test-"+suite.id)
    suiteElement.data('suite', suite)
    $(result.tests).each (i, test) =>
      @addClickTestHandler(test, suiteElement)

  handleError: (message) =>
    @element.find(".test-result-error").html(message)
    @element.find('.test-status').empty()
    @finishTestRun()

  finishTestRun: =>
    new Crucible.Summary()
    new Crucible.TestRunReport()
    @progress.parent().collapse('hide')
    @progress.find('.progress-bar').css('width',"0%")
    @element.find('.execute').removeClass('disabled')
    @element.find('.past-test-runs-selector').attr("disabled", false)
    @renderPastTestRunsSelector()
    @element.dequeue("executionQueue")

  addClickTestHandler: (test, suiteElement) => 
    handle = suiteElement.find(".suite-handle[data-key='#{test.key}']")
    handle.click =>
      suiteElement.find(".suite-handle").removeClass('active')
      handle.addClass('active')
      suiteElement.find('.test-results').empty().append(HandlebarsTemplates[@templates.testResult]({test: test}))
      suiteElement.find(".data-link").click (e) -> 
        $('#data-modal .modal-body').empty().append($(e.target).parent().find('.data-content').html())
        hljs.highlightBlock($('#data-modal .modal-body')[0]);

  flashWarning: (message) =>
    warningBanner = @element.find('.warning-message')
    $(warningBanner).html(message)
    $(warningBanner).fadeIn()
    $(warningBanner).delay(1000).fadeOut(1500)

  filterTestsByStarburst: (node) ->
    starburstNode = @starburst.nodeMap[node]
    testIds = _.union(starburstNode.failedIds, starburstNode.skippedIds, starburstNode.errorsIds, starburstNode.passedIds)
    elements = @element.find('.test-run-result')
    if (node == 'FHIR')
      elements.show()
      return
    $(elements).each (i, suiteElement) =>
      suiteElement = $(suiteElement)
      suite = suiteElement.data('suite')
      childrenIds = suite.methods.map (m) -> m.id
      if (_.intersection(testIds, childrenIds).length > 0)
        suiteElement.show()
      else
        suiteElement.hide()

  transitionTo: (node) ->
    _.defer(=>
      @filterTestsByStarburst(node))
