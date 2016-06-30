$(document).ready( -> 
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
        auth_element = $(".authorization-handle")
        auth_element.removeClass("hidden")
        authUrl = conformance_tab.data('authorize-url')
        $('#authorize_form').attr("action", authUrl)
        auth_enabled = !!auth_element.data('oauthClientId')
        if auth_enabled
          auth_expires_at = new Date() + 10000 # start at a future date if no expiration set
          auth_expires_at = moment.unix(parseInt(auth_element.data('oauthExpiresAt'))).toDate() if !!auth_element.data('oauthExpiresAt')
          auth_expired = auth_expires_at < new Date()
          auth_token_exists = !!auth_element.data('oauthRefreshToken')

          if !auth_expired || auth_token_exists
            auth_element.addClass("authorize-success")
            auth_element.attr('title', '').tooltip()
          else
            auth_element.attr('title', 'Authorization expired.').tooltip()
        else
          auth_element.attr('title', 'Please enter authorization information.').tooltip()

    )
    $("#authorize_form").on('submit', (event) =>
      event.preventDefault()
      $.post("/servers/#{$('#conformance-data').data('server-id')}/oauth_params",
      {
          client_id: $('#client_id').val(),
          client_secret: $('#client_secret').val(),
          authorize_url: $('#conformance-data').children().data('authorize-url'),
          token_url: $('#conformance-data').children().data('token-url'),
          state: $('#state').val(),
          launch_param: $('#launch_param').val(),
          patient_id: $('#patient_id').val(),
          scopes: $(event.target).find("[name='scope_vars[]']:checked").map(() ->
                    $(this).val()
                  ).get().join(",")
      },
      'JSON'
      ).success((data)->
        if $("#launch_check").prop('checked')
          $('#launch_param').addClass('used')
        scope = $(event.target).find("[name='scope_vars[]']:checked").map(() ->
          $(this).val()
        ).get().join(" ")
        $("#scope").val(scope)
        window.location.assign(event.target.action + "?" + $("input.used").serialize())
      )
      return false
    )
