$(document).ready( ->
  new Crucible.TestExecutor()
)

class Crucible.TestExecutor
  suites: []
  suitesById: {}
  testsById: {}
  templates:
    suiteSelect: 'views/templates/servers/suite_select'
    suiteGroup: 'views/templates/servers/suite_group'
    suiteResult: 'views/templates/servers/suite_result'
    testResult: 'views/templates/servers/partials/test_result'
    testRequests: 'views/templates/servers/partials/test_requests'
    testRequestDetails: 'views/templates/servers/partials/test_request_details'
    testRunSummary: 'views/templates/servers/partials/test_run_summary'
  html:
    deselectAllButton: '<i class="fa fa-close"></i>'
    selectAllButton: '<i class="fa fa-check"></i>'
    collapseAllButton: '<i class="fa fa-compress"></i>'
    expandAllButton: '<i class="fa fa-expand"></i>'
    spinner: '<span class="fa fa-lg fa-fw fa-spinner fa-pulse tests"></span>'
    unavailableError: '<div class="alert alert-danger"><strong>Error: </strong> Server conformance could not be loaded</div>'
    genericError: '<div class="alert alert-danger"><strong>Error: </strong> Tests could not be executed</div>'
    unauthorizedError: '<div class="alert alert-danger"><strong>Error: Server unauthorized or authorization expired</strong></div>'
  filters:
    search: ""
    executed: false
    starburstNode: null
    supported: true
    failures: false
  statusWeights: {'pass': 1, 'skip': 2, 'fail': 3, 'error': 4}
  checkStatusTimeout: 4000
  selectedTestRunId: null
  nextTestRunId: null
  previousTestRunId: null
  defaultSelection: null

  constructor: ->
    @element = $('.test-executor')
    return unless @element.length
    @element.data('testExecutor', this)
    @serverId = @element.data('server-id')
    @runningTestRunId = @element.data('current-test-run-id')
    @progress = $("##{@element.data('progress')}")
    @registerHandlers()
    @defaultSelection = @parseDefaultSelection(window.location.hash)
    $('#test-data-tab').trigger('click') if @defaultSelection
    @loadTests()
    @element.find('.filter-by-executed').css('display', 'none')
    @element.find('.filter-by-failures').css('display', 'none')

  registerHandlers: =>
    @element.find('.execute').click(@startTestRun)
    $('#cancel-modal #cancel-confirm').click(@cancelTestRun)
    @element.find('.selectDeselectAll').click(@selectDeselectAll)
    @element.find('.expandCollapseAll').click(@expandCollapseAll)
    @element.find('.clear-past-run-data').click(@clearPastTestRunData)
    @element.find('.filter-by-executed a').click(@filterByExecutedHandler)
    @element.find('.filter-by-failures a').click(@filterByFailuresHandler)
    @element.find('.filter-by-supported a').click(@filterBySupportedHandler)
    # turn off toggling for tags
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
    $('#conformance-data').on('conformanceError', (event) =>
      @filterBySupportedHandler()
      false
    )
    @bindToolTips()

  bindToolTips: =>
    @element.find('.selectDeselectAll').tooltip()
    @element.find('.expandCollapseAll').tooltip()
    @element.find('.clear-past-run-data').tooltip()
    @element.find('.change-test-run').tooltip()
    @element.find('.close-change-test-run').tooltip()

  loadTests: =>
    $.getJSON("/servers/#{@serverId}/supported_tests.json").success((data) =>
      @suites = data['tests']
      @renderSuites() if !@defaultSelection
      @continueTestRun() if @runningTestRunId && !@defaultSelection
      @filter(supported: true)
      @renderPastTestRunsSelector({text: 'Select past test run', value: '', disabled: true, selected: true})
      $('.test-result-loading').hide() if !@defaultSelection
    )

  renderSuites: =>
    @element.find('.test-results .button-holder').removeClass('hide')
    suitesElement = @element.find('.test-suites')
    suitesElement.empty()
    groupings = @buildGroupings(@suites)
    $(groupings).each (i, group) =>
      suitesElement.append(HandlebarsTemplates[@templates.suiteGroup]({group: group}))

      $(group.suites).each (i, suite) =>
        @suitesById[suite.id] = suite
        $(suite.methods).each (j, test) =>
          @testsById[test.id] = test

        suiteElement = suitesElement.find("#test-#{suite.id}")
        suiteElement.data('suite', suite)
        $(suite.methods).each (i, test) =>
          @addClickTestHandler(test, suiteElement)

  buildGroupings: (suites) =>
    groupingMap = {}
    for suite in suites
      groupingMap[suite.category.id] ||= $.extend({suites: []}, suite.category)
      groupingMap[suite.category.id].suites.push suite
    _.values(groupingMap).sort (left, right) -> if left.id >= right.id then 1 else -1

  renderPastTestRunsSelector: (elementToAdd, callback) =>
    $.getJSON("/servers/#{@serverId}/past_runs").success (data) =>
      return unless data
      foundDefaultSelection = false
      selector = @element.find('.past-test-runs-selector')
      selector.empty()
      if elementToAdd
        option = $("<option>#{elementToAdd.text}</option>")
        option.attr('value', elementToAdd.value)
        option.attr('disabled', true) if elementToAdd.disabled
        option.attr('selected', true) if elementToAdd.selected
        selector.append(option)

      selector.show()
      $(data['past_runs']).each (i, test_run) =>
        foundDefaultSelection = true if @defaultSelection && @defaultSelection.testRunId == test_run.id
        selection = "<option value='#{test_run.id}'> #{moment(test_run.date).format('MM/DD/YYYY, HH:mm')} </option>"
        selector.append(selection)

      if @defaultSelection
        # add a temporary option to the select box if this is a cancelled run
        selector.prepend( "<option value='#{@defaultSelection.testRunId}'>Cancelled</option>") if !foundDefaultSelection
        @togglePastRunsSelector() # Mimic showing the date dropdown, will be toggled off later
        selector.val(@defaultSelection.testRunId) # this is what identifies which run to show
        @updateCurrentTestRun()
        # remove the temporary option from the select box if this is a cancelled run
        selector.find("option[value='#{@defaultSelection.testRunId}']").remove() if !foundDefaultSelection

      callback() if callback

  clearPastTestRunData: =>
    @hideTestResultSummary()
    @element.find('.selected-run').empty()
    @element.find('.clear-past-run-data').hide()
    @renderSuites()
    @filter(executed: false)
    $('.expandCollapseAll').html(@html.expandAllButton)
    $('.selectDeselectAll').html(@html.selectAllButton)

  updateCurrentTestRun: =>
    @element.find('.test-suites').empty()
    @element.find('.execute').hide()
    @element.find('.suite-selectors').hide()
    @hideTestResultSummary()
    $('.selectDeselectAll').html(@html.deselectAllButton)
    $('.expandCollapseAll').html(@html.expandAllButton)
    $('.test-result-loading').show()
    selector = @element.find('.past-test-runs-selector')
    @selectedTestRunId = selector.val()
    selectedIndex = selector.find(":selected").index()
    @nextTestRunId = null
    @nextTestRunId = selector.find("option:eq(#{selectedIndex-1})").val() if selectedIndex > 1
    @previousTestRunId = null
    @previousTestRunId = selector.find("option:eq(#{selectedIndex+1})").val() if selectedIndex < selector.find("option").size()-1
    suiteIds = $($.map(selector.find('option'), (e) -> e.value))
    $.getJSON("/servers/#{@serverId}/test_runs/#{@selectedTestRunId}").success((data) =>
      return unless data
      @showTestRunSummary(data.test_run)
      @renderSuites()
      $(data['test_run'].test_results).each (i, result) =>
        suiteId = result.test_id
        suiteElement = @element.find("#test-#{suiteId}")
        formatted_result = {
          tests: result.result,
          setup_requests: result.setup_requests,
          setup_message: result.setup_message,
          teardown_requests: result.teardown_requests
        }
        @handleSuiteResult(@suitesById[suiteId], formatted_result, suiteElement) if @suitesById[suiteId]
      if @defaultSelection
        @element.find("#test-#{@defaultSelection.suiteId} a.collapsed").click()
        @element.find("#test-#{@defaultSelection.suiteId} ##{@defaultSelection.testId}").click().closest(".suite-group").children('a').trigger('click')
        @defaultSelection = null #prevent from auto-navigation from default selection any more
      @filter(supported: data.test_run.supported_only)
      @filter(executed: true, supported: (if data.test_run.supported_only then true else false))
      # set the date/time on the selected run display
      @element.find('.selected-run').html("#{moment(data.test_run.date).format('MM/DD/YYYY, HH:mm')}")
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

  togglePastRunsSelector: =>
    @element.find('.display-data-changer').toggle()
    @element.find('.display-data').toggle()
    @element.find('.close-change-test-run').toggle()
    @element.find('.change-test-run').toggle()

  toggleFilterSelector: =>
    @element.find('.add-filter-link').toggle()
    @element.find('.add-filter-selector').toggle()

  selectDeselectAll: =>
    button = $('.selectDeselectAll')
    if button.html() == @html.selectAllButton
      # open all categories first
      @element.find('.suite-group-body').collapse('show')
      $('.expandCollapseAll').html(@html.collapseAllButton)
      @element.find('.test-run-result :visible :checkbox').prop('checked', true)
      $(button).html(@html.deselectAllButton)
    else
      @element.find('.test-run-result :checkbox').prop('checked', false)
      $(button).html(@html.selectAllButton)


  expandCollapseAll: =>
    suiteGroupBodies = @element.find('.suite-group-body')
    button = $('.expandCollapseAll')
    if !$(suiteGroupBodies).hasClass('in')
      $(suiteGroupBodies).collapse('show')
      $(button).html(@html.collapseAllButton)
    else
      $(suiteGroupBodies).collapse('hide')
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
    @hideTestResultSummary()
    @progress.find('.progress-bar').css('width',"2%")
    @element.queue("executionQueue", @checkTestRunStatus)
    @element.queue("executionQueue", @refreshPastRunsAfterTestRun)
    @element.queue("executionQueue", @finishTestRun)

    suiteIds.each (i, suiteId) =>
      suiteElement = @element.find("#test-#{suiteId}")
      suiteElement.find("input[type=checkbox]").attr("checked", true)
      suiteElement.find('.test-status').empty().append(@html.spinner)
      suiteElement.addClass("executed")

    @element.find('.test-run-result').hide()
    @filter(executed: true)

  continueTestRun: =>
    $.get("/servers/#{@serverId}/test_runs/#{@runningTestRunId}").success((result) =>
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
        @runningTestRunId = result.test_run.id
        @element.dequeue("executionQueue")
      )
    else
      @flashWarning('Please select at least one test suite')

  cancelTestRun: =>
    if @runningTestRunId?
      $.post("/servers/#{@serverId}/test_runs/#{@runningTestRunId}/cancel").success( (result) =>
        location.reload()
      )
    else
      $("#cancel-modal").hide()

  searchBoxHandler: =>
    @filter(search: @searchBox.val().toLowerCase().replace(/\W/g, ''))

  filterByExecutedHandler: =>
    @filter(executed: false)
    false

  filterByFailuresHandler: =>
    @filter(failures: false)
    false

  filterBySupportedHandler: =>
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

    @element.find('.filter-by-executed').css('display', (if @filters.executed then 'inline-block' else 'none'))
    @element.find('.filter-by-supported').css('display', (if @filters.supported then 'inline-block' else 'none'))
    @element.find('.filter-by-failures').css('display', (if @filters.failures then 'inline-block' else 'none'))

    starburstTestIds = _.union(@filters.starburstNode.failedIds, @filters.starburstNode.skippedIds, @filters.starburstNode.errorsIds, @filters.starburstNode.passedIds) if @filters.starburstNode?
    $(suiteElements).each (i, suiteElement) =>
      suiteElement = $(suiteElement)
      suite = suiteElement.data('suite')
      childrenIds = suite.methods.map (m) -> m.id
      suiteElement.hide() if @filters.search.length > 0 && (suite.name.toLowerCase().replace(/\W/g,'')).indexOf(@filters.search) < 0
      suiteElement.hide() if @filters.executed && !suiteElement.hasClass("executed")
      suiteElement.hide() if @filters.starburstNode? && !(_.intersection(starburstTestIds, childrenIds).length > 0)
      suiteElement.hide() if @filters.supported && !(suite.supported)
      suiteElement.hide() if @filters.failures && suiteElement.find(".test-status .passed").length

    # hide the groups when no tests underneath are visible
    suiteGroups = @element.find('.suite-group')
    suiteGroups.show()
    suiteGroups.each (i, group) =>
      visibleCount = 0
      for result in $(group).find(".test-run-result")
        visibleCount += 1 if $(result).css('display') != 'none'
      $(group).hide() unless visibleCount > 0
      $(group).find('.suite-count').html("#{visibleCount} suite#{if visibleCount != 1 then 's' else ''}")

    # filter tests in a suite
    testElements = @element.find('.suite-handle')
    testElements.show()
    $(testElements).each (i, testElement) =>
      testElement = $(testElement)
      test = @testsById[testElement.attr('id')]
      testElement.hide() if test && @filters.supported && !(test.supported)

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
    return false unless @runningTestRunId?
    $.get("/servers/#{@serverId}/test_runs/#{@runningTestRunId}").success((result) =>
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
        $(".authorization-handle").removeClass("authorize-success")
        $(".authorization-handle").attr('title', 'Authorization failed').tooltip()
        @element.dequeue("executionQueue")
      else if test_run.status == "error"
        @displayError(@html.genericError)
        @element.dequeue("executionQueue")
      else if test_run.status == "finished"
        @nextTestRunId = null
        @previousTestRunId = null
        @previousTestRunId = @element.find('.past-test-runs-selector').children().eq(1).val() if @element.find('.past-test-runs-selector').children().length > 1
        @showTestRunSummary({test_results: test_run.test_results})
        @element.dequeue("executionQueue")
        $(".test-run-summary-handle").show() #show the summary tab if it now exists

      else if test_run.status != "cancelled" and @runningTestRunId?
        setTimeout(@checkTestRunStatus, @checkStatusTimeout)
    )

  showTestRunSummary: (results) =>
    summaryPanel = @element.find('.testrun-summary')
    summaryData = {
      suites: {total: 0},
      tests: {total: 0}
    }

    for status, weight of @statusWeights
      summaryData.suites[status] = 0
      summaryData.tests[status] = 0

    $(results.test_results).each (i, suite) =>
      suiteStatus = 'pass'
      $(suite.result).each (j, test) =>
        suiteStatus = test.status if @statusWeights[suiteStatus] < @statusWeights[test.status]
        summaryData.tests[test.status]++
        summaryData.tests.total++
      summaryData.suites[suiteStatus]++
      summaryData.suites.total++

    summaryContent = HandlebarsTemplates[@templates.testRunSummary](summaryData)
    summaryPanel.replaceWith(summaryContent)
    summaryPanel.show()

    @element.find(".testrun-summary-previous").hide() if @previousTestRunId == null
    @element.find(".testrun-summary-next").hide() if @nextTestRunId == null
    selector = @element.find('.past-test-runs-selector')

    @element.find(".testrun-summary-previous").click (e) =>
      selector.val(@previousTestRunId)
      @togglePastRunsSelector() # Mimic showing the date dropdown, will be toggled off later
      @updateCurrentTestRun()
    @element.find(".testrun-summary-next").click (e) =>
      selector.val(@nextTestRunId)
      @togglePastRunsSelector() # Mimic showing the date dropdown, will be toggled off later
      @updateCurrentTestRun()

  hideTestResultSummary: =>
    @element.find('.testrun-summary').hide()

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
      test.test_result_id = result._id if !test.test_result_id && result._id # id may come from different spots depending on if just run
      if (i == 0)
        # add click handler for default selection
        @addClickRequestDetailsHandler(test, suiteElement)
        testRunId = @selectedTestRunId
        testRunId = @runningTestRunId if @runningTestRunId
        @addClickPermalinkHandler(testRunId, suiteElement, test.id)
      @addClickTestHandler(test, suiteElement)

    # Add in click handlers for setup, teardown (non-tests)
    @addClickTestHandler({key: suite.id + '-setup', description: 'Set up test prerequisites', message: result.setup_message, requests: result.setup_requests}, suiteElement)
    @addClickTestHandler({key: suite.id + '-teardown', description: 'Clean up after test', requests: result.teardown_requests}, suiteElement)

  displayError: (message) =>
    @element.find(".test-result-error").html(message)
    @element.find('.test-status').empty()

  refreshPastRunsAfterTestRun: =>
    @renderPastTestRunsSelector({text: 'Select past test run', value: '', disabled: true},(=> @element.dequeue("executionQueue")))

  finishTestRun: =>
    new Crucible.ServerSummary()
    new Crucible.StarburstSummary()
    @progress.parent().collapse('hide')
    @progress.find('.progress-bar').css('width',"0%")
    @element.find('.execute').show()
    @element.find('.suite-selectors').show()
    @element.find('.cancel').hide()
    @element.find('.past-test-runs-selector').attr("disabled", false)
    $('.selectDeselectAll').html(@html.deselectAllButton)
    run_date = @element.find('.past-test-runs-selector').children().eq(1).html()
    @element.find('.selected-run').empty().html(run_date)
    @element.find('.clear-past-run-data').show()
    $("#cancel-modal").hide()
    @selectedTestRunId = @runningTestRunId
    @runningTestRunId = null

  addClickTestHandler: (test, suiteElement) =>
    handle = suiteElement.find(".suite-handle[data-key='#{test.key}']")
    handle.click =>
      suiteElement.find(".suite-handle").removeClass('active')
      handle.addClass('active')
      suiteElement.find('.test-results').empty().append(HandlebarsTemplates[@templates.testResult]({test: test}))
      testRunId = @selectedTestRunId
      testRunId = @runningTestRunId if @runningTestRunId
      @addClickRequestDetailsHandler(test, suiteElement)
      @addClickPermalinkHandler(testRunId, suiteElement, test.id)

  addClickRequestDetailsHandler: (test, suiteElement) =>
    suiteElement.find(".data-link").click (e) =>
      html = HandlebarsTemplates[@templates.testRequests]({test: test})
      detailsTemplate = @templates.testRequestDetails
      $('#data-modal .modal-body').empty().append(html)
      $('#data-modal .modal-body code').each (index, code) ->
        hljs.highlightBlock(code)
      refresh_link = $('#data-modal .request-panel-refresh')
      refresh_link.tooltip()
      refresh_link.click (e) ->
        e.preventDefault
        test_result_id = test.test_result_id.$oid
        test_id = test.id
        request_index = $(@).data('index')
        refresh_icon = $(@).find('i')
        content_panel = $("#request_#{request_index}")
        loading_html='<div style="text-align:center"><i class="fa fa-lg fa-fw fa-spinner fa-pulse"></i> Loading</div>'
        refresh_icon.addClass('fa-spin')
        content_panel.empty().append(loading_html)
        content_panel.collapse('show')
        $.getJSON("/test_results/#{test_result_id}/reissue_request.json?test_id=#{test_id}&request_index=#{request_index}").success((data) =>
          refresh_icon.removeClass('fa-spin')
          detailsHtml = HandlebarsTemplates[detailsTemplate]({index: request_index, call: data})
          $("#request_#{request_index}_status").html(data.response.code)
          content_panel.empty().append(detailsHtml)
          content_panel.find(".request-resent-message").show()
        )

  addClickPermalinkHandler: (testRunId, suiteElement, testId) =>
    permalink = suiteElement.find(".test-permalink-link")
    return unless permalink.length
    suiteId = suiteElement.attr("id").substring(5) #strip off "test-" prefix
    hash="##{testRunId}/#{suiteId}/#{testId}"
    path="#{window.location.protocol}//#{window.location.host}#{window.location.pathname}#{hash}"
    permalink.attr("href",hash)
    permalink.click (e) => e.preventDefault()
    clipboard = new Clipboard(permalink[0], text: () => path)
    clipboard.on('success', () => suiteElement.find(".permalink-copied").fadeIn('slow'))
    clipboard.on('error', () => window.location.hash=hash) #fallback mainly for safari

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

  parseDefaultSelection: (hash) =>
    return null if hash.split("/").length != 3
    [testRunId, suiteId, testId] = hash.substring(1).split("/")
    return {testRunId: testRunId, suiteId: suiteId, testId: testId}

  transitionTo: (node) ->
    _.defer(=>
      @filterTestsByStarburst(node))
