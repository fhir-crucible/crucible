$(document).ready( ->
  new Crucible.ServerSummary()
)

class Crucible.ServerSummary
  templates:
    failures: 'servers/failures_report'

  constructor: ->
    @element = $('.test-run-report')
    return unless @element.length
    @serverId = @element.data('server-id')
    @registerHandlers()
    @failuresReportElement = @element.find('.common-failures')
    @loadAggregateRun()

  registerHandlers: =>
    @element.find('.starburst').on('starburstInitialized', (event) =>
      @starburst = @element.find('.starburst').data('starburst')
      @starburst.addListener(this)
      @renderHeader(@starburst.selectedNode)
      @renderServerHeader()
      @loadHistory()
      false
    )

  renderFailures: ->
    messageMap = {}
    @failures = _.sortBy(@failures, (v) -> "#{v.key} #{v.description}")
    total = 0
    for failure in @failures
      continue if failure.hidden
      total += 1
      messageMap[failure.message] ||= {message: failure.message, failures: []}
      messageMap[failure.message].failures.push failure
    failuresByMessage = _.sortBy(_.values(messageMap), (v) -> -v.failures.length)
    @failuresReportElement.html(HandlebarsTemplates[@templates.failures]({failuresByMessage: failuresByMessage[0..24], total: failuresByMessage.length, count: failuresByMessage[0..24].length }))
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

  renderHistory: (data) =>
    dopplerElement = @element.find('.server-history').empty()
    doppler = new Crucible.Doppler(dopplerElement[0], data, @starburst)
    doppler.render()

  loadHistory: =>
    $.getJSON("/servers/#{@serverId}/summary_history.json").success((data) =>
      @renderHistory(data)
    )

  renderHeader: (node) ->
    starburstNode = @starburst.nodeMap[node]
    # @element.find('.starburst-header').html("#{starburstNode.name}:\n<p>#{starburstNode.passed} / #{starburstNode.total} passed (#{@_percent(starburstNode, 'passed')}%)</p>")

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
      @renderHeader(node)
      @filterFailures(node))
