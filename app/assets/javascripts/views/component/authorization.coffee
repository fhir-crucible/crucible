$(window).on('load', ->
  new Crucible.Authorization()
)

class Crucible.Authorization
  constructor: ->
    @element = $('#authorization-tab')
    return unless @element.length
    @registerHandlers()

  registerHandlers: =>
    $('#conformance-data').on('conformanceLoaded', (event) =>
      $('#authorize_app').attr("disabled", false)
    )
    @element.find("#authorize_app").on('click', (event) =>
      event.preventDefault()

      false
    )
