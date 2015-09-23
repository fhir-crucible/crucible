$(window).on('load', -> 
  new Crucible.TestExecutor()
)

class Crucible.TestExecutor
  suites: []
  suitesById: {}
  templates: 
    suiteSelect: 'views/templates/servers/suite_select'
    suiteResult: 'views/templates/servers/suite_result'
    testResult: 'views/templates/servers/test_result'
  html:
    selectAllButton: '<i class="fa fa-check"></i>&nbsp;Deselect All Test Suites'
    deselectAllButton: '<i class="fa fa-check"></i>&nbsp;Select All Test Suites'
    collapseAllButton: '<i class="fa fa-expand"></i>&nbsp;Collapse All Test Suites'
    expandAllButton: '<i class="fa fa-expand"></i>&nbsp;Expand All Test Suites'
    spinner: '<span class="fa fa-lg fa-fw fa-spinner fa-pulse tests"></span>'

  constructor: ->
    @element = $('.test-executor')
    @registerHandlers()
    @loadTests()

  registerHandlers: =>
    @element.find('.execute').click(@execute)
    @element.find('.selectDeselectAll').click(@selectDeselectAll)
    @element.find('.expandCollapseAll').click(@expandCollapseAll)
    @element.find('.filter-by-executed a').click(@showAllSuites)

  loadTests: =>
    $.getJSON("api/tests.json").success((data) => 
      @suites = data['tests']
      @renderSuites()
    )

  renderSuites: =>
    suitesElement = @element.find('.test-suites')
    suitesElement.empty()
    $(@suites).each (i, suite) =>
      @suitesById[suite.id] = suite
      suitesElement.append(HandlebarsTemplates[@templates.suiteSelect]({suite: suite}))

  selectDeselectAll: =>
    suiteElements = @element.find('.test-run-result :checkbox')
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
    @showOnlyExecutedSuites()
    progress = $("##{this.element.data('progress')}")
    progress.parent().collapse('show')
    progress.find('.progress-bar').css('width',"2%")
    suiteIds.each (i, suiteId) =>
      testElement = @element.find("#test-#{suiteId}")
      testElement.find('.test-status').empty().append(@html.spinner)
      @element.queue("executionQueue", =>
        $.post("#{$(location).attr('pathname')}/tests/#{suiteId}/execute").success((result) =>
          progress.find('.progress-bar').css('width',"#{(i+1)/suiteIds.length*100}%")
          @handleSuiteResult(@suitesById[suiteId], result, testElement)
          if i < suiteIds.length-1
            setTimeout((=> @element.dequeue("executionQueue")), 1)
          else
            progress.parent().collapse('hide')
            progress.find('.progress-bar').css('width',"0%")
        )
      )
    @element.dequeue("executionQueue")

  showAllSuites: =>
    @element.find('.filter-by-executed').collapse('hide')
    @element.find('.test-run-result').show()

  showOnlyExecutedSuites: =>
    @element.find('.filter-by-executed').collapse('show')
    @element.find('.test-run-result').hide()
    @element.find(':checked').closest('.test-run-result').show()
    @element.find('.test-run-result.executed').show()
    
  handleSuiteResult: (suite, result, testElement) =>
    testElement.replaceWith(HandlebarsTemplates[@templates.suiteResult]({suite: suite, result: result}))
    testElement = @element.find("#test-"+suite.id)
    $(result.tests).each (i, test) =>
      handle = testElement.find(".suite-handle[data-key='#{test.key}']")
      handle.click =>
        testElement.find(".suite-handle").removeClass('active')
        handle.addClass('active')
        testElement.find('.test-results').empty().append(HandlebarsTemplates[@templates.testResult]({test: test}))

