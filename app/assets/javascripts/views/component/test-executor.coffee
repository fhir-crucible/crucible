$(window).on('load', ->
  new Crucible.TestExecutor()
)

class Crucible.TestExecutor
  suites: []
  suitesById: {}
  testsById: {}
  templates:
    suiteSelect: 'views/templates/servers/suite_select'
    suiteResult: 'views/templates/servers/suite_result'
    testResult: 'views/templates/servers/partials/test_result'
    testRequests: 'views/templates/servers/partials/test_requests'
  html:
    selectAllButton: '<i class="fa fa-close"></i>'
    deselectAllButton: '<i class="fa fa-check"></i>'
    collapseAllButton: '<i class="fa fa-compress"></i>'
    expandAllButton: '<i class="fa fa-expand"></i>'
    spinner: '<span class="fa fa-lg fa-fw fa-spinner fa-pulse tests"></span>'
    unavailableError: '<div class="alert alert-danger"><strong>Error: </strong> Server Unavailable</div>'
    genericError: '<div class="alert alert-danger"><strong>Error: </strong> Tests could not be executed</div>'
    unauthorizedError: '<div class="alert alert-danger"><strong>Error: Server unauthorized or authorization expired</strong></div>'
  filters:
    search: ""
    executed: false
    starburstNode: null
    supported: true
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
    $('#cancel-modal #cancel-confirm').click(@cancelTestRun)
    @element.find('.selectDeselectAll').click(@selectDeselectAll)
    @element.find('.expandCollapseAll').click(@expandCollapseAll)
    @element.find('.clear-past-run-data').click(@clearPastTestRunData)
    @element.find('.filter-by-executed a').click(@filterByExecutedHandler)
    @element.find('.filter-by-supported a').click(@filterBySupportedHandler)
    # turn off toggling for tags
    @element.find('.filter-by-executed').collapse({toggle: false})
    @element.find('.filter-by-supported').collapse({toggle: false})
    @element.find('.change-test-run').click(@togglePastRunsSelector)
    @element.find('.close-change-test-run').click(@togglePastRunsSelector)
    @element.find('.past-test-runs-selector').change(@updateCurrentTestRun)
    @element.find('.add-filter-link').click(@toggleFilterSelector)
    @element.find('.filter-selector').change(@addFilter)
    @element.find('.add-filter-selector a').click(@toggleFilterSelector)
    @searchBox = @element.find('.test-results-filter')
    @searchBox.on('keyup', @searchBoxHandler)
    @element.find('.starburst').on('starburstInitialized', (event) =>
      @starburst = @element.find('.starburst').data('starburst')
      @starburst.addListener(this)
      if @filters.starburstNode
        @starburst.transitionTo(@filters.starburstNode.name, 0)
      false
    )
    $('#conformance-data').on('conformanceInitialized', (event) =>
      @loadTests()
      false
    )
<<<<<<< ee26c885987eb55416a173db36b096e5c8c2037a
    @bindToolTips()

  bindToolTips: =>
    @element.find('.selectDeselectAll').tooltip()
    @element.find('.expandCollapseAll').tooltip()
    @element.find('.clear-past-run-data').tooltip()
    @element.find('.change-test-run').tooltip()
    @element.find('.close-change-test-run').tooltip()
=======
    $('#conformance-data').on('conformanceError', (event) =>
      @filterBySupportedHandler()
      false
    )
>>>>>>> clear supported only if the conformance errors out

  loadTests: =>
    $.getJSON("/servers/#{@serverId}/supported_tests.json").success((data) =>
      @suites = data['tests']
      @renderSuites()
      @continueTestRun() if @testRunId
      @renderPastTestRunsSelector({text: 'Select past test run', value: '', disabled: true})
      @filter(supported: true)
    ).complete(() -> $('.test-result-loading').hide())

  renderSuites: =>
    @element.find('.test-results .button-holder').removeClass('hide')
    suitesElement = @element.find('.test-suites')
    suitesElement.empty()
    $(@suites).each (i, suite) =>
      @suitesById[suite.id] = suite
      $(suite.methods).each (j, test) =>
        @testsById[test.id] = test
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
        selector.append("<option value='#{elementToAdd.value}' disabled='#{elementToAdd.disabled}'>#{elementToAdd.text}</option>")
      selector.show()
      $(data['past_runs']).each (i, test_run) =>
        selection = "<option value='#{test_run.id}'> #{moment(test_run.date).format('MM/DD/YYYY')} </option>"
        selector.append(selection)
    )

  clearPastTestRunData: =>
    @element.find('.selected-run').empty()
    @element.find('.clear-past-run-data').hide()
    @renderSuites()
    @filter(executed: false)

  updateCurrentTestRun: =>
    @element.find('.test-suites').empty()
    @element.find('.execute').hide()
    @element.find('.suite-selectors').hide()
    $('.test-result-loading').show()
    selector = @element.find('.past-test-runs-selector')
    testRunId = selector.val()
    suiteIds = $($.map(selector.find('option'), (e) -> e.value))
    $.getJSON("/servers/#{@serverId}/test_runs/#{testRunId}").success((data) =>
      return unless data
      @renderSuites()
      $(data['test_run'].test_results).each (i, result) =>
        suiteId = result.test_id
        suiteElement = @element.find("#test-#{suiteId}")
        @handleSuiteResult(@suitesById[suiteId], {tests: result.result}, suiteElement)
      @filter(supported: data.test_run.supported_only)
      @filter(executed: true, supported: (if data.test_run.supported_only then true else false))
      date = new Date(data.test_run.date)
      m = date.getMonth() + 1
      d = date.getDate()
      y = date.getFullYear()
      @setTestRunDateDisplay(m, d, y)
      @element.find('.clear-past-run-data').show()
      @element.find('.change-test-run').hide()
      @togglePastRunsSelector()
    ).complete(() -> 
      $('.execute').show()
      $('.suite-selectors').show()
      $('.test-result-loading').hide()
      selector.children().attr('selected', false)
      selector.children().first().attr('selected', true)
    )

  setTestRunDateDisplay: (month, day, year) =>
    @element.find('.selected-run').html(month + '/' + day + '/' + year)

  togglePastRunsSelector: =>
    @element.find('.display-data-changer').toggle()
    @element.find('.display-data').toggle()
    @element.find('.close-change-test-run').toggle()
    @element.find('.change-test-run').toggle()

  toggleFilterSelector: =>
    @element.find('.add-filter-link').toggle()
    @element.find('.add-filter-selector').toggle()

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
    @element.find('.execute').hide()
    @element.find('.suite-selectors').hide()
    @element.find('.cancel').show()
    @resetSuitePanels()
    @progress.parent().collapse('show')
    @element.find('.past-test-runs-selector').attr("disabled", true)
    @renderPastTestRunsSelector({text: 'Test in progress...', value: '', disabled: true})
    @progress.find('.progress-bar').css('width',"2%")
    @element.queue("executionQueue", @checkTestRunStatus)
    @element.queue("executionQueue", @finishTestRun)

    suiteIds.each (i, suiteId) =>
      suiteElement = @element.find("#test-#{suiteId}")
      suiteElement.find("input[type=checkbox]").attr("checked", true)
      suiteElement.find('.test-status').empty().append(@html.spinner)
      suiteElement.addClass("executed")

    @element.find('.test-run-result').hide()
    @filter(executed: true)

  continueTestRun: =>
    $.get("/servers/#{@serverId}/test_runs/#{@testRunId}").success((result) =>
      @filter(supported: result.test_run.supported_only)
      #@element.find('.filter-by-supported').collapse(if result.test_run.supported_only then 'show' else 'hide')
      @prepareTestRun($(result.test_run.test_ids))
      @element.dequeue("executionQueue")
    )

  startTestRun: =>
    suiteIds = $($.map(@element.find(':checked'), (e) -> e.name))
    @element.find(".test-result-error").empty()
    if suiteIds.length > 0
      @prepareTestRun(suiteIds)
      suiteIds = $.map(@element.find(':checked'), (e) -> e.name)
      $.post("/servers/#{@serverId}/test_runs.json", { test_ids: suiteIds, supported_only: @filters.supported }).success((result) =>
        @testRunId = result.test_run.id
        @element.dequeue("executionQueue")
      )
    else 
      @flashWarning('Please select at least one test suite')

  cancelTestRun: =>
    if @testRunId?
      $.post("/servers/#{@serverId}/test_runs/#{@testRunId}/cancel").success( (result) =>
        location.reload()
      )
    else 
      $("#cancel-modal").hide()

  searchBoxHandler: =>
    @filter(search: @searchBox.val().toLowerCase().replace(/\s/g, ""))

  filterByExecutedHandler: =>
    #@element.find('.filter-by-executed').collapse('hide')
    @filter(executed: false)
    false

  filterBySupportedHandler: =>
    #@element.find('.filter-by-supported').collapse('hide')
    @filter(supported: false)
    false

  addFilter: =>
    selector = @element.find('.filter-selector')
    filter = selector.val()
    @filters["#{filter}"] = true
    @filter(@filters)
    @toggleFilterSelector()
    selector.children().attr('selected', false)
    selector.children().first().attr('selected', true)

  filter: (filters)=>
    if filters?
      for f of filters
        @filters[f] = filters[f]
    # filter suites
    suiteElements = @element.find('.test-run-result')
    suiteElements.show()

    @element.find('.filter-by-executed').collapse((if @filters.executed then 'show' else 'hide'))
    @element.find('.filter-by-supported').collapse((if @filters.supported then 'show' else 'hide'))

    starburstTestIds = _.union(@filters.starburstNode.failedIds, @filters.starburstNode.skippedIds, @filters.starburstNode.errorsIds, @filters.starburstNode.passedIds) if @filters.starburstNode?
    $(suiteElements).each (i, suiteElement) =>
      suiteElement = $(suiteElement)
      suite = suiteElement.data('suite')
      childrenIds = suite.methods.map (m) -> m.id
      suiteElement.hide() if @filters.search.length > 0 && (suite.name.toLowerCase()).indexOf(@filters.search) < 0
      suiteElement.hide() if @filters.executed          && !suiteElement.hasClass("executed")
      suiteElement.hide() if @filters.starburstNode?    && !(_.intersection(starburstTestIds, childrenIds).length > 0)
      suiteElement.hide() if @filters.supported         && !(suite.supported)
    # filter tests in a suite
    testElements = @element.find('.suite-handle')
    testElements.show()
    $(testElements).each (i, testElement) =>
      testElement = $(testElement)
      test = @testsById[testElement.attr('id')]
      testElement.hide() if @filters.supported          && !(test.supported)

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
    return false unless @testRunId?
    $.get("/servers/#{@serverId}/test_runs/#{@testRunId}").success((result) =>
      test_run = result.test_run
      percent_complete = test_run.test_results.length / test_run.test_ids.length
      @progress.find('.progress-bar').css('width',"#{(Math.max(2, percent_complete * 100))}%")
      if Object.keys(@processedResults).length < test_run.test_results.length
        for result in test_run.test_results
          suiteId = result.test_id
          suite = @suitesById[suiteId]
          suiteElement = $("#test-#{suiteId}")
          @handleSuiteResult(suite, result, suiteElement) unless @processedResults[suiteId]
          @processedResults[suiteId] = true
        @filter()
      if test_run.status == "unavailable"
        @displayError(@html.unavailableError)
        @element.dequeue("executionQueue")
      else if test_run.status == "unauthorized"
        @displayError(@html.unauthorizedError)
        @element.dequeue("executionQueue")
      else if test_run.status == "error"
        @displayError(@html.genericError)
        @element.dequeue("executionQueue")
      else if test_run.status == "finished"
        @element.dequeue("executionQueue")
      else if test_run.status != "cancelled" and @testRunId?
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
      if (i == 0)
        # add click handler for default selection
        @addClickRequestDetailsHandler(test, suiteElement)
      @addClickTestHandler(test, suiteElement)

  displayError: (message) =>
    @element.find(".test-result-error").html(message)
    @element.find('.test-status').empty()

  finishTestRun: =>
    new Crucible.Summary()
    new Crucible.TestRunReport()
    @progress.parent().collapse('hide')
    @progress.find('.progress-bar').css('width',"0%")
    @element.find('.execute').show()
    @element.find('.suite-selectors').show()
    @element.find('.cancel').hide()
    @element.find('.past-test-runs-selector').attr("disabled", false)
    @renderPastTestRunsSelector({text: 'Select past test run', value: '', disabled: true})
    run_date = @element.find('.past-test-runs-selector').children().last().html()
    @element.find('.selected-run').empty().html(run_date)
    @element.find('')
    @element.find('.clear-past-run-data').show()
    $("#cancel-modal").hide()
    @testRunId = null

  addClickTestHandler: (test, suiteElement) => 
    handle = suiteElement.find(".suite-handle[data-key='#{test.key}']")
    handle.click =>
      suiteElement.find(".suite-handle").removeClass('active')
      handle.addClass('active')
      suiteElement.find('.test-results').empty().append(HandlebarsTemplates[@templates.testResult]({test: test}))
      @addClickRequestDetailsHandler(test, suiteElement)

  addClickRequestDetailsHandler: (test, suiteElement) =>
    suiteElement.find(".data-link").click (e) => 
      html = HandlebarsTemplates[@templates.testRequests]({test: test})
      $('#data-modal .modal-body').empty().append(html)
      $('#data-modal .modal-body code').each (index, code) ->
        hljs.highlightBlock(code)

  flashWarning: (message) =>
    warningBanner = @element.find('.warning-message')
    $(warningBanner).html(message)
    $(warningBanner).fadeIn()
    $(warningBanner).delay(1000).fadeOut(1500)

  filterTestsByStarburst: (node) ->
    if node == 'FHIR'
      @filter(starburstNode: null)
    else
      @filter(starburstNode: @starburst.nodeMap[node])

  transitionTo: (node) ->
    _.defer(=>
      @filterTestsByStarburst(node))
