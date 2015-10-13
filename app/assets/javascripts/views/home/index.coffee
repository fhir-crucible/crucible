$(window).on('load', ->
  new Crucible.Home()
)

class Crucible.Home

  constructor: ->
    @element = $('#new-server-form')
    return unless @element.length
    @registerHandlers()

  registerHandlers: =>
    @element.validate(
      rules: 
        "server[url]": 
          required: true
          url: true
    )

