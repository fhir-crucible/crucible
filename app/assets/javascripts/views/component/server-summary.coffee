$(document).ready( ->
  new Crucible.ServerSummary()
)

class Crucible.ServerSummary
  templates:
    failures: 'views/templates/servers/failures_report'
    recentRuns: 'views/templates/servers/recent_runs'

  constructor: ->
    @element = $('.test-run-report')
    return unless @element.length
    @serverId = @element.data('server-id')
    @registerHandlers()
    @failuresReportElement = @element.find('.common-failures')
    @recentRunsReportElement = @element.find('.recent-runs')
    @loadAggregateRun()

  registerHandlers: =>
    @element.find('.starburst').on('starburstInitialized', (event) =>
      @starburst = @element.find('.starburst').data('starburst')
      @starburst.addListener(this)
      @renderHeader(@starburst.selectedNode)
      @loadHistory()
      false
    )
    $('.past-test-runs-selector').on('testRunsLoaded', (event) =>
      pastRunsSelector = $('.past-test-runs-selector')
      pastRuns = pastRunsSelector.data('testRuns').past_runs
      pastRuns = pastRuns.slice(0,50) # only show most cent
      @recentRunsReportElement.html(HandlebarsTemplates[@templates.recentRuns]({pastRuns: pastRuns}))
      @recentRunsReportElement.find('.recent-runs-item').click( (event) ->
        id = $(@).data('id')
        $('.change-test-run').trigger('click')
        pastRunsSelector.val(id).trigger('change')
        $('#test-data-tab').trigger('click')
      )
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
