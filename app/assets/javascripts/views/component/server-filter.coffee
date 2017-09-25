$(document).ready( ->
  new Crucible.ServerFilter()
)

class Crucible.ServerFilter
  margin:  {top: 0, right: 0, bottom: 0, left: 0}
  width: 40
  height: 700
  searchVisible: false
  active: true
  fhirVersion: 'all'

  constructor: ->
    @element = $('.server-summaries')
    @containerElement = $('.server-rows')
    return unless @element.length
    @registerHandlers()

  registerHandlers: =>
    @element.find('#filters_stu3').on('click', () =>
      @element.find('#filters_stu3').parent().find('button').removeClass('active')
      @element.find('#filters_stu3').addClass('active')
      @setVersion('STU3')
      @containerElement.trigger('filterchange')
      false
    )

    @element.find('#filters_dstu2').on('click', () =>
      @element.find('#filters_dstu2').parent().find('button').removeClass('active')
      @element.find('#filters_dstu2').addClass('active')
      @setVersion('DSTU2')
      @containerElement.trigger('filterchange')
      false
    )

    @element.find('#filters_all_versions').on('click', () =>
      @element.find('#filters_all_versions').parent().find('button').removeClass('active')
      @element.find('#filters_all_versions').addClass('active')
      @setVersion('all')
      @containerElement.trigger('filterchange')
      false
    )

    @element.find('#filters_active').on('click', () =>
      @element.find('#filters_active').parent().find('button').removeClass('active')
      @element.find('#filters_active').addClass('active')
      @setActive(true)
      @containerElement.trigger('filterchange')
      false
    )

    @element.find('#filters_all').on('click', () =>
      @element.find('#filters_all').parent().find('button').removeClass('active')
      @element.find('#filters_all').addClass('active')
      @setActive(false)
      @containerElement.trigger('filterchange')
      false
    )
    # @element.find('#filters_all').on('click', () => @setActive(false))

    @element.find('#sortorder_percent_passed').on('click', () =>
      @element.find('#sortorder_percent_passed').parent().find('button').removeClass('active')
      @element.find('#sortorder_percent_passed').addClass('active')
      sortedElements = @containerElement.find('.server-item').toArray().sort (a, b) => $(b).data('percent') - $(a).data('percent')

      @containerElement.empty()

      $.each(sortedElements, (i,el) =>
        @containerElement.append(el)
      )
      @containerElement.trigger('sortchange')
      false
    )


    @element.find('#sortorder_recently_tested').on('click', () =>
      @element.find('#sortorder_recently_tested').parent().find('button').removeClass('active')
      @element.find('#sortorder_recently_tested').addClass('active')
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
        @element.find('.btn-group').hide()
        @element.find('.server-filters-label').hide()
        @element.find('#server-search-input').show().focus().val('')
      else
        @element.find('#filter_search').removeClass('fa-close').addClass('fa-search')
        @element.find('.btn-group').show()
        @element.find('.server-filters-label').show()
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
    @filterElements()

  setVersion: (fhirVersion) =>
    @fhirVersion = fhirVersion
    @filterElements()

  filterElements: =>
    @containerElement.find('.server-item').each (index, item) =>
      $item = $(item)
      if (!@active || $item.data('active')) && (@fhirVersion == 'all' || $item.data('fhirVersion') == @fhirVersion)
        $item.show()
      else
        $item.hide()
    

