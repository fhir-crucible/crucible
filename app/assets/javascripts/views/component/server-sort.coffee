$(document).ready( ->
  new Crucible.ServerSort()
)

class Crucible.ServerSort
  margin:  {top: 0, right: 0, bottom: 0, left: 0}
  width: 40
  height: 700

  constructor: ->
    @element = $('.server-sortorder')
    @containerElement = $('.server-rows')
    return unless @element.length
    @registerHandlers()

  registerHandlers: =>
    @element.find('#sortorder_percent_passed').on('click', () =>
      @element.find('a').removeClass('selected')
      @element.find('#sortorder_percent_passed').addClass('selected')
      @containerElement.find('.server-item')
        .sort( (a, b) =>
          return 1 if $(a).data('passed')/$(a).data('total')  < $(b).data('passed')/$(b).data('total')
          return -1 if $(a).data('passed')/$(a).data('total') > $(b).data('passed')/$(b).data('total')
          0
        )
        .each( (i,e) =>
          elem = $(e)
          elem.remove()
          elem.appendTo(@containerElement)
        )
      @containerElement.trigger('sortchange')
      false
    )

    @element.find('#sortorder_recently_tested').on('click', () =>
      @element.find('a').removeClass('selected')
      @element.find('#sortorder_recently_tested').addClass('selected')
      @containerElement.find('.server-item')
        .sort( (a, b) =>
          return 1 if $(a).data('daysold') > $(b).data('daysold')
          return -1 if $(a).data('daysold') < $(b).data('daysold')
          0
        )
        .each( (i,e) =>
          elem = $(e)
          elem.remove()
          elem.appendTo(@containerElement)
        )
      @containerElement.trigger('sortchange')
      false
    )

