$(window).on('load', ->
  new Crucible.Conformance()
)

class Crucible.Conformance
  @operations: ["read", "vread", "update", "delete", "history-instance", "validate", "history-type", "create", "search-type"]
  templates:
    conformanceError: 'views/templates/servers/conformance_error'

  constructor: ->
    @element = $('#conformance-data')
    return unless @element.length
    @template = HandlebarsTemplates['views/templates/servers/conformance']
    @serverId = @element.data('server-id')
    @loadConformance()

  loadConformance: (refresh) =>
    refreshParam = if refresh then '?refresh=true' else ''
    _.defer(=>
      $.getJSON("/servers/#{@serverId}/conformance#{refreshParam}")
      .success ((data) =>
        @updateConformance(data)
        @removeConformanceSpinner()
        @element.trigger('conformanceInitialized') if data.conformance.updated
      )
      .error ((data) =>
        @removeConformanceSpinner()
        @element.html(HandlebarsTemplates[@templates.conformanceError]())
      )
      .complete () =>
        @element.find('#refresh-conformance-link').click =>
          $("#conformance_spinner").show()
          @loadConformance(true)

    )

  updateConformance: (data)=>
    @conformance = data.conformance
    html = @template({conformance: data.conformance, testedResources: @testedResources(), operations: Crucible.Conformance.operations, supportedStatus: @supportedStatus, authType: @authType(), authorizeUrl: @oauthUrl("authorize"), tokenUrl: @oauthUrl("token") })
    @element.html(html)
    @element.trigger('conformanceLoaded')

  removeConformanceSpinner: =>
    $("#conformance_spinner").hide()

  testedResources: =>
    resources = []
    validatedResourceTypes = []
    ensureArray(@conformance.rest).forEach((mode) ->
      resources = resources.concat(mode.resource) if mode.resource
    )
    resources

  oauthUrl: (url) =>
    if @authType() == "OAuth2"
      auth = @conformance.rest?[0].security?.extension?[0].extension?.filter((elem)->
        elem.url == url
      )[0]
      auth.value.value if auth

  authType: =>
      if @conformance.rest[0].security && @conformance.rest[0].security.extension
        switch @conformance.rest[0].security.extension[0].url
          when "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris" then "OAuth2"
      else
        "none"

  ensureArray = (array) ->
    array || []
