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
      sortedElements = @containerElement.find('.server-item').toArray().sort (a, b) => $(b).data('percent') - $(a).data('percent')

      @containerElement.empty()

      $.each(sortedElements, (i,el) =>
        @containerElement.append(el)
      )
      @containerElement.trigger('sortchange')
      false
    )

    @element.find('#sortorder_recently_tested').on('click', () =>
      @element.find('a').removeClass('selected')
      @element.find('#sortorder_recently_tested').addClass('selected')
      sortedElements = @containerElement.find('.server-item').toArray().sort (a, b) => $(b).data('lastrun') - $(a).data('lastrun')

      @containerElement.empty()

      $.each(sortedElements, (i,el) =>
        @containerElement.append(el)
      )
      @containerElement.trigger('sortchange')
      false
    )

