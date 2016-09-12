$(document).ready( ->
  new Crucible.Dashboard()
)

class Crucible.Dashboard

  statusWeights: {'none': 0, 'pass': 1, 'skip': 2, 'fail': 3, 'error': 4}
  statusLabels: {'none': 'Not Run', 'pass': 'Passing', 'skip': 'Skipped', 'fail': 'Failing', 'error': 'Error'}

  templates:
    serverResultsRow: 'views/templates/dashboards/server_result_row'
    suiteResult: 'views/templates/servers/suite_result'
    testResult: 'views/templates/servers/partials/test_result'
    testRequests: 'views/templates/servers/partials/test_requests'

  constructor: ->
    @element = $('.dashboard-element')
    return unless @element.length
    @id = this.element.data('dashboard-id')
    @renderServerResults()

  renderServerResults: =>
    $.getJSON("/dashboards/#{@id}/results.json").success((data) =>
      $('.dashboard-body > div').empty()
      $(data.suites).each (j, suite) =>
        $(data.servers).each (i, server) =>
          serverResults = data.resultsByServer[server._id.$oid][suite.id]['results']
          lastUpdated = data.resultsByServer[server._id.$oid][suite.id]['last_updated']
          lastUpdated = moment(lastUpdated).fromNow() if lastUpdated?
          suiteStatus = 'none'
          $(serverResults).each (i, serverResult) =>
            suiteStatus = serverResult.status if @statusWeights[suiteStatus] < @statusWeights[serverResult.status]
          suite.status = suiteStatus
          suite.statusLabel = @statusLabels[suiteStatus]
          serverResults = suite.methods if serverResults.length == 0
          html = HandlebarsTemplates[@templates.serverResultsRow]({server: server, suite: suite, lastUpdated: lastUpdated, result: {tests: serverResults}})
          $("#suite_results_#{suite.id}").append(html)
          suiteElement = $("#dash-#{server._id.$oid}-#{suite.id}")
          $(serverResults).each (i, test) =>
            if (i == 0)
              # add click handler for default selection
              @addClickRequestDetailsHandler(test, suiteElement)
            @addClickTestHandler(test, suiteElement)
      $('.results-rectangle').tooltip()
      $('.results-circle').tooltip()
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
