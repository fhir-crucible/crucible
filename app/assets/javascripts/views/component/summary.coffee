$(window).on('load', -> 
  new Crucible.Summary()
)

# returns percent passing of a section
# TODO: this needs to be somewhere better... also on starburst
percentMe = (data) ->
  if data.total == 0
    0
  else
    Math.round(data.passed / data.total * 100)

class Crucible.Summary
  constructor: ->
    $('.summary').each (index, summaryElement) =>
      summaryElement = $(summaryElement)
      serverId = summaryElement.data('serverId')
      if serverId?
        $.getJSON("/api/summary/#{serverId}.json")
          .success((data) => 
            if (data.summary)
              starburstElement = summaryElement.find('.starburst')
              summaryElement.show()
              # TODO: _renderChart seems messy... this could use a better interface
              starburst = new Crucible.Starburst(starburstElement[0], data.summary.compliance)
              starburst._renderChart()
              if summaryElement.data('synchronized')
                starburst.addListener(this)
              summaryElement.data('generated-at', data.summary.generated_at)
              summaryElement.find('.percent-passed').html("#{percentMe(starburst.data)}%")
              summaryElement.find('.last-run').html(moment(data.summary.generated_at).fromNow())
              starburstElement.data('starburst', starburst).trigger('starburstInitialized')
            else
              summaryElement.hide()
          )
          .error((e) ->
            summaryElement.hide()
          )

  transitionTo: (name) ->
    $('.summary[data-synchronized=true]').find('.starburst').each (i,element) ->
      starburst = $(element).data('starburst')
      if name != starburst.selectedNode
        starburst.transitionTo(name)
