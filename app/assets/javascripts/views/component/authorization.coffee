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
      $('.authorize_form_element').attr("disabled", false)
      authUrl = $('#conformance-data').children().data('authorize-url')
      $('#authorize_form').attr("action", authUrl)
    )
    @element.find("#authorize_form").on('submit', (event) =>

    )
