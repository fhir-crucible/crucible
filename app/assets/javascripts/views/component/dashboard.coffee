$(window).on('load', ->
  new Crucible.Dashboard()
)

class Crucible.Dashboard

  servers: [{"name": 'Argonaut Reference Server', "results" : [1,2,3,4]},
            {"name":'Smart Reference Server', "results" : [5, 6, 7, 8, 5, 5, 5]}]

  rectData: [{"test_name": 'test1', "test_result" : 'result1'},
             {"test_name": 'test2', "test_result" : 'result2'}]

  templates:
    serverResultsRow: 'views/templates/dashboards/server_result_row'

  constructor: ->
    @element = $('.dashboard-element')
    @renderServerResults()

  renderServerResults: =>
    dashboardBody = d3.select('.dashboard-body > div')
    $(@servers).each (i, server) =>
      newTempl = HandlebarsTemplates[@templates.serverResultsRow]({server: server})
      $('.dashboard-body > div').append(newTempl)
    dashboardBody.selectAll("rect").data(@rectData).enter()