$(document).ready( ->
  new Crucible.ServerScroller()
)

colors = ["#bd0026", "#f03b20", "#fd8d3c", "#fecc5c", "#c2e699", "#78c679", "#31a354", "#006837"]

class Crucible.ServerScroller
  margin:  {top: 0, right: 0, bottom: 0, left: 0}
  width: 40
  height: 760

  constructor: ->
    @element = $('.server-scroller')
    @containerElement = $('.server-rows')
    return unless @element.length
    @registerHandlers()
    @loadData()

  registerHandlers: =>
    @containerElement.on('sortchange', () =>
      @updateOrder()
    )

  color: (normalized_score) =>
    scaled = normalized_score/100 * (colors.length - 1)
    floor = Math.floor(scaled)
    remainder = scaled - floor
    color = d3.interpolateRgb(colors[floor], colors[floor+1])(remainder)

  loadData: =>
    $.getJSON('/server_scrollbar_data')
      .success((data) =>
        @renderChart(data.servers) if (data.servers)
      )

  updateOrder: () =>
    @containerElement.find('.server-item').each( (index, element) =>
      $(element).find('.server-rank').text(index + 1)
      scroller_element = @element.find("#scroller-element-#{$(element).data('serverid')}")
      scroller_element.attr("y", scroller_element.attr("height") * index)
    )

  renderChart: (data) =>

    data = _.sortBy(data, (d) => -d.percent_passing)

    dragstarted = (d) =>
      d3.event.sourceEvent.stopPropagation()
      d3.select('#scroller').classed("dragging", true)

    dragged = (d) =>
      d.y = Math.max(10, Math.min(@['height'] - 10 - 15 * @['height']/data.length,d3.event.y))
      d3.select('#scroller').attr("y", d.y)
      @_move((d.y - 10) / (@['height']-20 - 15 * @['height']/data.length))

    dragended = (d) => d3.select('#scroller').classed("dragging", false)

    drag = d3.behavior.drag()
      .origin((d) => d)
      .on("dragstart", dragstarted)
      .on("drag", dragged)
      .on("dragend", dragended)

    svg = d3.select(@element[0]).append("svg")
      .attr("width", @['width'])
      .attr("height", @['height'])
      .append("g")
      .attr("transform", "translate(" + @['margin'].left + "," + @['margin'].top + ")")

    click = (d,i ) =>
      scroller_element = @element.find("#scroller-element-#{d.id}")
      percent = scroller_element.attr('y') / @['height']
      newY = Math.min(@['height'] - 15 * @['height']/data.length - 10, 10 + percent * @['height'])
      @_move(Math.max(0, Math.min(1, scroller_element.index()/(data.length-15))))
      d3.select("#scroller").attr("y",newY).data([{y: newY}])

    servers = svg.selectAll(".servers")
      .data(data)
      .enter()
      .append("rect")
      .attr("width", @['width'])
      .attr("height", @['height'] / data.length)
      .attr("id", (d) => "scroller-element-#{d.id}")
      .attr("x", 0)
      .attr("y", (d,i) => i * @['height'] / data.length)
      .style("fill", (d) => @color(d.percent_passing))
      .on("click", click)

    selected = svg.selectAll('selector')
      .data([{y: 10}])
      .enter()
      .append("rect")
      .attr("id", 'scroller')
      .attr("x", () => 10)
      .attr("y", (d) -> d.y)
      .attr("width", @['width']-20)
      .attr("height", 15 * @['height'] / data.length)
      .style("fill", "#fff")
      .style("opacity", .5)
      .style("rx", 10)
      .style("ry", 10)
      .call(drag)

  _move: (percent) =>
    @containerElement.css('top', "#{10 - percent * (@containerElement.height() - @['height'])}px")
