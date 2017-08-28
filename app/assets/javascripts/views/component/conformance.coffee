$(document).ready( ->
  new Crucible.Conformance()
)

class Crucible.Conformance
  @operations: ['read', 'vread', 'update', 'patch', 'delete', 'history-instance', 'history-type', 'create', 'search-type']
  templates:
    conformanceError: 'views/templates/servers/conformance_error'

  constructor: ->
    @element = $('#conformance-data')
    @server_fhir_version = $('#server-fhir-version')
    @mismatch_alert_element = $('#fhir-sequence-mismatch')
    return unless @element.length
    @template = HandlebarsTemplates['views/templates/servers/conformance']
    @version_mismatch_template = HandlebarsTemplates['views/templates/servers/partials/fhir_version_notification']
    @serverId = @element.data('server-id')
    @loadConformance()

  loadConformance: (refresh) =>
    refreshParam = if refresh then '?refresh=true' else ''
    _.defer(=>
      $.getJSON("/servers/#{@serverId}/conformance#{refreshParam}")
      .success ((data) =>
        @updateConformance(data)
        @removeConformanceSpinner()
        @mismatch_alert_element.hide()
        @server_fhir_version.html("#{data.fhir_sequence} (#{data.fhir_version})")
        if data.fhir_sequence != 'DSTU2' && data.fhir_sequence != 'STU3'
          @mismatch_alert_element.html(@version_mismatch_template(data))
          @mismatch_alert_element.show()
        @element.trigger('conformanceInitialized') if data.conformance.updated
        @registerHandlers()
      )
      .error ((data) =>
        @element.trigger('conformanceError')
        @removeConformanceSpinner()
        @element.html(HandlebarsTemplates[@templates.conformanceError]())
      )
      .complete () =>
        @element.find('#refresh-conformance-link').click =>
          $("#conformance_spinner").show()
          @loadConformance(true)
    )

  registerHandlers: =>
    @screenControls()

  screenControls: =>
    @element.find('.resources-changer').click(=> @changeScreens({controlButton: 'resources-changer', show: 'conformance-resources', hide: ['conformance-metadata']}))
    @element.find('.metadata-changer').click(=> @changeScreens({controlButton: 'metadata-changer', show: 'conformance-metadata', hide: ['conformance-resources']}))

  changeScreens: (params) =>
    @element.find('.screen-changer span').removeClass('active')
    activeButton = '.' + params.controlButton
    @element.find(activeButton).addClass('active')
    activeScreen = '.' + params.show
    for scr in params.hide
      inactiveScreen = '.' + scr
      @element.find(inactiveScreen).addClass('hide')
    @element.find(activeScreen).removeClass('hide')

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
      auth.valueUri if auth

  authType: =>
      if @conformance.rest[0].security && @conformance.rest[0].security.extension
        switch @conformance.rest[0].security.extension[0].url
          when "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris" then "OAuth2"
          else "none"
      else
        "none"

  ensureArray = (array) ->
    array || []
