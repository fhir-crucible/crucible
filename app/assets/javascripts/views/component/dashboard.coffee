$(window).on('load', ->
  new Crucible.Dashboard()
)

class Crucible.Dashboard

  servers: ['Argonaut Reference Server', 'Smart Reference Server']

  constructor: ->
    @element = $('.dashboard-element')
    

