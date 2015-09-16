$(window).on('load', -> 
  manager = new Crucible.SummaryManager()
  $('.summary').each (index, value) ->
    serverId = $(value).data('serverId')
    if serverId?
      $.getJSON("api/summary/#{serverId}.json")
        .success((data) -> 
          starburstElement = $(value).find('.starburst')
          starburst = new Crucible.Starburst(starburstElement[0], data.summary.compliance)
          starburst._renderChart()
          starburst.addListener(manager)
          starburstElement.data('starburst', starburst)
          $(value).find('.percent-passed').html("#{percentMe(starburst.data)}%")
          $(value).find('.last-run').html(moment(data.summary.generated_at).fromNow())
        )
        .error((e) ->
          $(value).remove()
        )
)

# returns percent passing of a section
percentMe = (data) ->
  if data.total == 0
    0
  else
    Math.round(data.passed / data.total * 100)

class Crucible.SummaryManager
  transitionTo: (name) ->
    $('.summary[data-synchronized=true]').find('.starburst').each (i,element) ->
      starburst = $(element).data('starburst')
      if name != starburst.selectedNode
        starburst.transitionTo(name)
