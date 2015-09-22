$(window).on('load', -> 
  new Crucible.TestExecutor()
)

class Crucible.TestExecutor
  tests: []

  constructor: ->
    @element = $('.test-executor')
    @element.find('.execute').click(@execute)
    @element.find('.selectDeselectAll').click(@selectDeselectAll)
    @element.find('.expandCollapseAll').click(@expandCollapseAll)

    $.getJSON("api/tests.json").success((data) => 
      @tests = data['tests']
      @renderSuites()
    )

  renderSuites: =>
    suitesElement = @element.find('.test-suites')
    suitesElement.empty()
    $(@tests).each (i, test) =>
      html = HandlebarsTemplates['views/templates/servers/test_select']({test: test})
      suitesElement.append(html)

  selectDeselectAll: =>
    suiteElements = @element.find('.test-run-result :checkbox')
    button = $('.selectDeselectAll')
    if !$(suiteElements).prop('checked')
      $(suiteElements).prop('checked', true)
      $(button).html('<i class="fa fa-check"></i>&nbsp;Deselect All Test Suites')
    else
      $(suiteElements).prop('checked', false)
      $(button).html('<i class="fa fa-check"></i>&nbsp;Select All Test Suites')

  expandCollapseAll: =>
    suiteElements = @element.find('.test-run-result .collapse')
    button = $('.expandCollapseAll')
    if !$(suiteElements).hasClass('in')    
      $(suiteElements).each (i, panel) ->
        $(panel).collapse('show')
      $(button).html('<i class="fa fa-expand"></i>&nbsp;Collapse All Test Suites')
    else
      $(suiteElements).each (i, panel) ->
        $(panel).collapse('hide')
        $(button).html('<i class="fa fa-expand"></i>&nbsp;Expand All Test Suites')

  execute: =>
    tests = $($.map(@element.find(':checked'), (e) -> e.name))
    progress = $("##{this.element.data('progress')}")
    progress.parent().collapse('show')
    progress.find('.progress-bar').css('width',"2%")
    tests.each (i, test) =>
      testElement = @element.find("#test-#{test}")
      testElement.find('.test-status').removeClass('hidden')
      @element.queue("executionQueue", =>
        console.log(test)
        $.ajax({
          type: 'POST',
          url: "#{$(location).attr('pathname')}/tests/#{test}/execute",
          success: ((data) =>
            progress.find('.progress-bar').css('width',"#{(i+1)/tests.length*100}%")
            if i < tests.length-1
              setTimeout((=> @element.dequeue("executionQueue")), 1)
            else
              progress.parent().hide()
            )
        });
      )
    @element.dequeue("executionQueue")
    
