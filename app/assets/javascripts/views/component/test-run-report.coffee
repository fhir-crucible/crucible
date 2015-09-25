$(window).on('load', -> 
  new Crucible.TestRunReport()
)

class Crucible.TestRunReport
  # templates: 
  #   suiteSelect: 'views/templates/servers/suite_select'
  # html:
  #   selectAllButton: '<i class="fa fa-check"></i>&nbsp;Deselect All Test Suites'

  constructor: ->
    @element = $('.test-run-report')
    @registerHandlers()

  registerHandlers: =>
    # @element.find('.execute').click(@execute)
    @element.find('.starburst').on('starburstInitialized', =>
      @element.find('.starburst').data('starburst').addListener(this)
    )

  onTransition: (node) ->
    debugger

