$(document).ready( ->
  new Crucible.ServerFilter()
)

class Crucible.ServerFilter
  margin:  {top: 0, right: 0, bottom: 0, left: 0}
  width: 40
  height: 700
  searchVisible: false
  active: false

  constructor: ->
    @element = $('.server-summaries')
    @containerElement = $('.server-rows')
    return unless @element.length
    @registerHandlers()

  registerHandlers: =>
    @element.find('#filters_active').on('click', () =>
      @element.find('#filters_active').parent().parent().find('a').removeClass('selected')
      @element.find('#filters_active').addClass('selected')
      @setActive(true)
      @containerElement.trigger('filterchange')
      false
    )

    @element.find('#filters_all').on('click', () =>
      @element.find('#filters_all').parent().parent().find('a').removeClass('selected')
      @element.find('#filters_all').addClass('selected')
      @setActive(false)
      @containerElement.trigger('filterchange')
      false
    )
    # @element.find('#filters_all').on('click', () => @setActive(false))

    @element.find('#sortorder_percent_passed').on('click', () =>
      @element.find('#sortorder_percent_passed').parent().parent().find('a').removeClass('selected')
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
      @element.find('#sortorder_recently_tested').parent().parent().find('a').removeClass('selected')
      @element.find('#sortorder_recently_tested').addClass('selected')
      sortedElements = @containerElement.find('.server-item').toArray().sort (a, b) => $(b).data('lastrun') - $(a).data('lastrun')

      @containerElement.empty()

      $.each(sortedElements, (i,el) =>
        @containerElement.append(el)
      )
      @containerElement.trigger('sortchange')
      false
    )

    @element.find('#filter_search').on('click', (el) =>

      if !@searchVisible
        @element.find('#filter_search').removeClass('fa-search').addClass('fa-close')
        @element.find('li').hide()
        @element.find('#server-search-input').show().focus().val('')
      else
        @element.find('#filter_search').removeClass('fa-close').addClass('fa-search')
        @element.find('li').show()
        @element.find('#server-search-input').hide().val('').trigger('keyup')
        @setActive(@active)

      @searchVisible = !@searchVisible
    )

    @element.find('#server-search-input').on('keyup', (e) =>
      if e.keyCode == 27 # esc key
        @element.find('#filter_search').removeClass('fa-close').addClass('fa-search')
        @element.find('li').show()
        @element.find('#server-search-input').hide().val('').trigger('keyup')
        @setActive(@active)
      else
        filter = @element.find('#server-search-input').val().toLowerCase()
        @containerElement.find('.server-item').each (index, item) =>
          $item = $(item)
          searchString = ($item.data('servername') + $item.data('serverurl')).toLowerCase()
          if searchString.indexOf(filter) >= 0
            $item.show()
          else
            $item.hide()

      @containerElement.trigger('filterchange', filter)
    )

  setActive: (active) =>
    @active = active
    @containerElement.find('.server-item').each (index, item) =>
      $item = $(item)
      if !@active || $item.data('active')
        $item.show()
      else
        $item.hide()
    

