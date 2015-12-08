$(window).on('load', ->
  new Crucible.Dashboard()
)

class Crucible.Dashboard

  statusWeights: {'none': 0, 'pass': 1, 'skip': 2, 'fail': 3, 'error': 4}

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
      $(data.suites).each (j, suite) =>
        $(data.servers).each (i, server) =>
          serverResults = data.resultsByServer[server._id.$oid][suite.id]
          suiteStatus = 'none'
          $(serverResults).each (i, serverResult) =>
            suiteStatus = serverResult.status if @statusWeights[suiteStatus] < @statusWeights[serverResult.status]
          suite.status = suiteStatus
          serverResults = suite.methods if serverResults.length == 0
          html = HandlebarsTemplates[@templates.serverResultsRow]({server: server, suite: suite, result: {tests: serverResults}})
          
          suiteElement = $("#suite_results_#{suite.id}").append(html)
          $(serverResults).each (i, test) =>
            @addClickTestHandler(test, suiteElement)
    )


  addClickTestHandler: (test, suiteElement) => 
    handle = suiteElement.find(".suite-handle[data-key='#{test.key}']")
    handle.click =>
      suiteElement.find(".suite-handle").removeClass('active')
      handle.addClass('active')
      suiteElement.find('.test-results').empty().append(HandlebarsTemplates[@templates.testResult]({test: test}))
      #@addClickRequestDetailsHandler(test, suiteElement)

  addClickRequestDetailsHandler: (test, suiteElement) =>
    suiteElement.find(".data-link").click (e) => 
      html = HandlebarsTemplates[@templates.testRequests]({test: test})
      $('#data-modal .modal-body').empty().append(html)
      $('#data-modal .modal-body code').each (index, code) ->
        hljs.highlightBlock(code)


