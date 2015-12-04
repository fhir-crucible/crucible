$(window).on('load', ->
  new Crucible.Dashboard()
)

class Crucible.Dashboard

  statusWeights: {'pass': 1, 'skip': 2, 'fail': 3, 'error': 4}

  templates:
    serverResultsRow: 'views/templates/dashboards/server_result_row'

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
    )

    # dashboardBody = d3.select('.dashboard-body > div')
    # dashboardBody.selectAll("rect").data(@rectData).enter()
