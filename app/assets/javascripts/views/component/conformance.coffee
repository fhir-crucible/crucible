$(window).on('load', ->
  new Crucible.Conformance()
)

class Crucible.Conformance
  @operations: ["read", "vread", "update", "delete", "historyInstance", "validate", "historyType", "create", "searchType"]

  constructor: ->
    @element = $('.metadata-expand-container')
    @template = HandlebarsTemplates['views/templates/servers/conformance']

    $.getJSON("/api#{$(location).attr('pathname')}/conformance")
    .success ((data) =>
      @updateConformance(data)
      @removeConformanceSpinner()
    )
    .error ((data) =>
      @removeConformanceSpinner()
    )

  updateConformance: (data)=>
    @conformance = data.conformance
    html = @template(({conformance: data.conformance, testedResources: @testedResources(), operations: Crucible.Conformance.operations, supportedStatus: @supportedStatus}))
    $("#conformance-data").children().replaceWith(html)

  removeConformanceSpinner: =>
    $("#conformance_spinner").remove()

  testedResources: =>
    resources = []
    validatedResourceTypes = []
    ensureArray(@conformance.rest).forEach((mode) ->
      resources = resources.concat(mode.resource)
    )
    resources

  ensureArray = (array) ->
    array || []
