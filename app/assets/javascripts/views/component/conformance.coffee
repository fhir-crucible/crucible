$(window).on('load', ->
  new Crucible.Conformance()
)

class Crucible.Conformance
  @operations: ["read", "vread", "update", "delete", "history-instance", "validate", "history-type", "create", "search-type"]

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
        @element.find('#refresh-conformance-link').click =>
          $("#conformance_spinner").show()
          @loadConformance(true)
      )
      .error ((data) =>
        @removeConformanceSpinner()
      )
    )

  updateConformance: (data)=>
    @conformance = data.conformance
    html = @template({conformance: data.conformance, testedResources: @testedResources(), operations: Crucible.Conformance.operations, supportedStatus: @supportedStatus, authType: @authType(), authorizeUrl: @oauthUrl("authorize"), tokenUrl: @oauthUrl("token") })
    @element.children().replaceWith(html)
    @element.trigger('conformanceLoaded')

  removeConformanceSpinner: =>
    $("#conformance_spinner").hide()

  testedResources: =>
    resources = []
    validatedResourceTypes = []
    ensureArray(@conformance.rest).forEach((mode) ->
      resources = resources.concat(mode.resource)
    )
    resources

  oauthUrl: (url) =>
    if @authType() == "OAuth2"
      auth = @conformance.rest[0].security.extension[0].extension.find((elem, ind, arr)->
        elem.url == url
      )
      auth.value.value

  authType: =>
      if @conformance.rest[0].security
        switch @conformance.rest[0].security.extension[0].url
          when "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris" then "OAuth2"
      else
        "none"

  ensureArray = (array) ->
    array || []
