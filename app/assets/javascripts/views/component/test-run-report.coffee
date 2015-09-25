$(window).on('load', -> 
  new Crucible.TestRunReport()
)

class Crucible.TestRunReport
  templates: 
    childrenChart: 'views/templates/servers/starburst_children_chart'
  # html:
  #   selectAllButton: '<i class="fa fa-check"></i>&nbsp;Deselect All Test Suites'

  constructor: ->
    @element = $('.test-run-report')
    @registerHandlers()
    @childrenChart = @element.find('.spec-details')


  registerHandlers: =>
    # @element.find('.execute').click(@execute)
    @element.find('.starburst').on('starburstInitialized', (event) =>
      @starburst = @element.find('.starburst').data('starburst')
      @starburst.addListener(this)
      @renderChart(@starburst.selectedNode)
      @renderHeader(@starburst.selectedNode)
      @renderServerHeader()
      false
    )

  renderChart: (node) ->
    children = @convertChildren(@starburst.nodeMap[node].children)
    @childrenChart.html(HandlebarsTemplates[@templates.childrenChart]({children: children}))

  renderHeader: (node) ->
    starburstNode = @starburst.nodeMap[node]
    @element.find('.starburst-header').html("#{starburstNode.name}:\n<p>#{starburstNode.passed} / #{starburstNode.total} passed (#{@_percent(starburstNode, 'passed')}%)</p>")

  renderServerHeader: ->
    @element.find('.percent-supported-value').html("#{@_percent(@starburst.data, 'passed')}%")
    @element.find('.last-run').html(moment(this.element.find('.summary').data('generated-at')).fromNow())


  convertChildren: (children) ->
    children.map (child) =>
      name: child.name
      percentFailed: @_percent(child, 'failed')
      percentPassed: @_percent(child, 'passed')
      percentUntested: @_percent(child, 'untested')

  _percent: (node, type) ->
    if (type == 'untested')
      val = 1-(node.passed + node.failed)/(node.total||1)
    else
      val = node[type]/(node.total||1)
    Math.round(val*100)


  transitionTo: (node) ->
    @renderChart(node)
    @renderHeader(node)

