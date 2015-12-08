$(window).on('load', ->
  new Crucible.Dashboard()
)

class Crucible.Dashboard

  statusWeights: {'pass': 1, 'skip': 2, 'fail': 3, 'error': 4}

  templates:
    serverResultsRow: 'views/templates/dashboards/server_result_row'
    suiteResult: 'views/templates/servers/suite_result'
    testResult: 'views/templates/servers/partials/test_result'

  constructor: ->
    @element = $('.dashboard-element')
    return unless @element.length
    @renderServerResults()

  renderServerResults: =>
    $.getJSON("/dashboards/argonaut/results.json").success((data) =>
      $('.dashboard-body > div').empty()
      $(data.servers).each (i, server) =>
        $(data.suites).each (j, suite) =>
          serverResults = data.resultsByServer[server._id.$oid][suite.id]
          suiteStatus = 'pass'
          $(serverResults).each (i, serverResult) =>
            suiteStatus = serverResult.status if @statusWeights[suiteStatus] < @statusWeights[serverResult.status]
          suite.status = suiteStatus
          html = HandlebarsTemplates[@templates.serverResultsRow]({server: server, suite: suite, result: {tests: serverResults}})
          suiteElement = $('.dashboard-body > div').append(html)
          $(serverResults).each (i, test) =>
            @addClickTestHandler(test, suiteElement)
    )


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


  #handleSuiteResult: (suite, result, suiteElement) =>
  #  suiteStatus = 'pass'
  #  if result.result
  #    result.tests = result.result
  #  $(result.tests).each (i, test) =>
  #    suiteStatus = test.status if @statusWeights[suiteStatus] < @statusWeights[test.status]
  #  result.suiteStatus = suiteStatus
  #  suiteElement.replaceWith(HandlebarsTemplates[@templates.suiteResult]({suite: suite, result: result}))
  #  suiteElement = @element.find("#test-"+suite.id)
  #  suiteElement.data('suite', suite)
  #  $(result.tests).each (i, test) =>
  #    if (i == 0)
  #      # add click handler for default selection
  #      @addClickRequestDetailsHandler(test, suiteElement)
  #    @addClickTestHandler(test, suiteElement)

