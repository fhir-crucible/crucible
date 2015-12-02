$(window).on('load', ->
  new Crucible.Dashboard()
)

class Crucible.Dashboard

  servers: [{"name": 'Argonaut Reference Server', "results" : [1,2,3,4]},
            {"name":'Smart Reference Server', "results" : [5, 6, 7, 8]}]

  rectData: [{"test_name": 'test1', "test_result" : 'result1'}
             {"test_name": 'test2', "test_result" : 'result2'}
             {"test_name": 'test3', "test_result" : 'result3'}]

  templates:
    serverResultsRow: 'views/templates/dashboards/server_result_row'

  constructor: ->
    @element = $('.dashboard-element')
    @renderServerResults()

  renderServerResults: =>
    dashboardBody = d3.select('.dashboard-body > div')
    for server in @servers
      debugger
      newTempl = HandlebarsTemplates[@templates.serverResultsRow]({server: server})
      $('.dashboard-body > div').append(newTempl)
      #newElem = dashboardBody.append("svg")
      #              .attr("width", 200)
      #              .attr("height", 200);
      #
      #newElem.append("rect")
      #             .attr("x", 0)
      #             .attr("y", 0)
      #             .attr("width", 18)
      #             .attr("height", 18);
      #
      #newElem.append("rect")
      #             .attr("x", 20)
      #             .attr("y", 0)
      #             .attr("width", 18)
      #             .attr("height", 18);