$(window).on('load', ->
  new Crucible.Authorization()
)

class Crucible.Authorization
  constructor: ->
    @element = $('#authorize-modal')
    return unless @element.length
    @registerHandlers()

  registerHandlers: =>
    $('#conformance-data').on('conformanceLoaded', (event) =>
      conformance_tab = $('#conformance-data').children()
      if conformance_tab.data('auth-type') != "none"
        $(".authorization-handle").removeClass("hidden")
        authUrl = conformance_tab.data('authorize-url')
        $('#authorize_form').attr("action", authUrl)
    )
    @element.find("#authorize_form").on('submit', (event) =>
      event.preventDefault()
      $.post("/api/servers/#{$('#conformance-data').data('server-id')}/oauth_params",
      {
          client_id: $('#client_id').val(),
          client_secret: $('#client_secret').val(),
          authorize_url: $('#conformance-data').children().data('authorize-url'),
          token_url: $('#conformance-data').children().data('token-url'),
          state: $('#state').val()
      },
      'JSON'
      ).success((data)->
        event.target.submit()
      )
      return false
    )
