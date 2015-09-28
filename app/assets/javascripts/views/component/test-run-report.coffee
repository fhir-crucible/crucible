$(window).on('load', -> 
  new Crucible.TestRunReport()
)

class Crucible.TestRunReport
  templates: 
    childrenChart: 'views/templates/servers/starburst_children_chart'
    failures: 'views/templates/servers/failures_report'
  # html:
  #   selectAllButton: '<i class="fa fa-check"></i>&nbsp;Deselect All Test Suites'

  constructor: ->
    @element = $('.test-run-report')
    return unless @element.length
    @serverId = @element.data('server-id')
    @registerHandlers()
    @childrenChart = @element.find('.spec-details')
    @failuresReportElement = @element.find('.failures')
    @loadAggregateRun()


  registerHandlers: =>
    @element.find('.starburst').on('starburstInitialized', (event) =>
      @starburst = @element.find('.starburst').data('starburst')
      @starburst.addListener(this)
      @renderChart(@starburst.selectedNode)
      @renderHeader(@starburst.selectedNode)
      @renderServerHeader()
      false
    )
    $('.test-executor').on('testsLoaded', (event) =>
      @suitesById = $(event.target).data('testExecutor').suitesById
      @renderFailures()
    )

  renderFailures: ->
    messageMap = {}
    @failures = _.sortBy(@failures, (v) -> "#{v.key} #{v.description}")
    for failure in @failures
      messageMap[failure.message] ||= {message: failure.message, failures: []}
      failure.suite = @suitesById[failure.test_id.$oid] if @suitesById?
      messageMap[failure.message].failures.push failure
    failuresByMessage = _.sortBy(_.values(messageMap), (v) -> -v.failures.length)
    @failuresReportElement.html(HandlebarsTemplates[@templates.failures]({failuresByMessage: failuresByMessage, total: @failures.length}))
    

  loadAggregateRun: =>
    $.getJSON("/api/servers/#{@serverId}/aggregate_run?only_failures=true").success((data) =>
      return unless data
      $('.test-run-summary-handle').removeClass('hidden')
      @failures = data['results']
      @renderFailures()
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

  filterFailures: (node) =>
    starburstNode = @starburst.nodeMap[node]
    # renderFailures() -- mark failures as hidden and remove
    # remove hidden

  transitionTo: (node) ->
    @renderChart(node)
    @renderHeader(node)
    @filterFailures(node)

