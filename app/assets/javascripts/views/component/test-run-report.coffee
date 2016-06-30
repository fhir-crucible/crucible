$(document).ready( ->  
  new Crucible.TestRunReport()
)

class Crucible.TestRunReport
  templates: 
    childrenChart: 'views/templates/servers/starburst_children_chart'
    failures: 'views/templates/servers/failures_report'

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
    total = 0
    for failure in @failures
      continue if failure.hidden
      total += 1
      messageMap[failure.message] ||= {message: failure.message, failures: []}
      failure.suite = @suitesById[failure.test_id] if @suitesById?
      messageMap[failure.message].failures.push failure
    failuresByMessage = _.sortBy(_.values(messageMap), (v) -> -v.failures.length)
    @failuresReportElement.html(HandlebarsTemplates[@templates.failures]({failuresByMessage: failuresByMessage, total: total}))
    @failuresReportElement.find(".data-link").click (e) -> 
      $('#data-modal .modal-body').empty().append($(e.target).parent().find('.data-content').html())
      hljs.highlightBlock($('#data-modal .modal-body')[0]);
    

  loadAggregateRun: =>
    $.getJSON("/servers/#{@serverId}/aggregate_run?only_failures=true").success((data) =>
      return unless data
      $('.test-run-summary-handle').removeClass('hidden')
      @failures = data['results']
      @renderFailures()
    )

  renderChart: (node) ->
    children = @convertChildren(@starburst.nodeMap[node].children || [@starburst.nodeMap[node]])
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
    failureIds = (starburstNode.failedIds.concat starburstNode.skippedIds).concat starburstNode.errorsIds
    for failure in @failures
      failure.hidden = (failureIds.indexOf(failure.id) < 0)
    @renderFailures() 

  transitionTo: (node) ->
    _.defer(=>
      @renderChart(node)
      @renderHeader(node)
      @filterFailures(node))

