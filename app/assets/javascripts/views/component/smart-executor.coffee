$(document).ready( ->
  new Crucible.SmartExecutor()
)

class Crucible.SmartExecutor
  templates:
    smartResult: 'views/templates/servers/partials/smart_result'

  constructor: ->
    @element = $('.smart-executor')
    return unless @element.length
    @element.data('smartExecutor', this)
    @loadResults()

  loadResults: =>
    $.getJSON("/smart/app/show").success((data) =>
      @element.html(HandlebarsTemplates[@templates.smartResult]({report: data.report}))
    )
