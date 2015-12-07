$(window).on('load', ->
  new Crucible.Dashboard()
)

class Crucible.Dashboard

  statusWeights: {'pass': 1, 'skip': 2, 'fail': 3, 'error': 4}

  templates:
    serverResultsRow: 'views/templates/dashboards/server_result_row'
    suiteResult: 'views/templates/servers/suite_result'

  constructor: ->
    @element = $('.dashboard-element')
    return unless @element.length
    @renderServerResults()

  renderServerResults: =>
    $.getJSON("/dashboards/argonaut/results.json").success((data) =>
      $('.dashboard-body > div').empty()
      $(data.servers).each (i, server) =>
        $(data.suites).each (j, suite) =>
          results = data.results[server._id.$oid][suite.id]
          suiteStatus = 'pass'
          $(results).each (i, result) =>
            suiteStatus = result.status if @statusWeights[suiteStatus] < @statusWeights[result.status]
          suite.status = suiteStatus
          html = HandlebarsTemplates[@templates.serverResultsRow]({server: server, suite: suite, results: results})
          $('.dashboard-body > div').append(html)
          suiteElement = $(html).find('.dash-details')
          newElem = HandlebarsTemplates[@templates.suiteResult]({suite: suite, result: results})
          suiteElement.replaceWith(newElem)
          debugger
    )



    # dashboardBody = d3.select('.dashboard-body > div')
    # dashboardBody.selectAll("rect").data(@rectData).enter()


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

