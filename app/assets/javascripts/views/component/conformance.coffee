$(window).on('load', ->
  new Crucible.Conformance()
)

class Crucible.Conformance

  constructor: ->
    @element = $('.metadata-expand-container')
    @template = HandlebarsTemplates['views/templates/servers/conformance']
    $.ajax({
        type: 'GET',
        url: "/api#{$(location).attr('pathname')}/conformance",
        dataType: 'JSON',
        success: ((data) =>
          @updateConformance(data)
          @removeConformanceSpinner()
        ),
        fail: ((data) =>
          @removeConformanceSpinner()
        )
    });

  updateConformance: (data)=>
    @conformance = data.conformance
    html = @template(({conformance: data.conformance, testedResources: @testedResources()}))
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
