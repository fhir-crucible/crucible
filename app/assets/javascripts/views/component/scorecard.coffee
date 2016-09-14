$(document).ready( ->
  new Crucible.ScoreCard()
)

colors = ["#bd0026", "#f03b20", "#fd8d3c", "#fecc5c", "#c2e699", "#78c679", "#31a354", "#006837"]

class Crucible.ScoreCard

  transitionTime: 2000

  constructor: ->
    @scorecard_element = $('.scorecard')
    return unless @scorecard_element.length
    @registerHandlers()
    @renderTotal($(element)) for element in @scorecard_element.find('.total-element')

  registerHandlers: ->
    @scorecard_element.find('.scorecard-score-another').click( () =>
      @scorecard_element.find('.scorecard-score-another').hide()
      @scorecard_element.find('.scorecard-form').show()
    )

  renderTotal: (element) ->

    min_score = 0
    min_score = parseInt element.data('min_score') if element.data('min_score')
    max_score = parseInt element.data('max_score')
    score = Math.max(min_score, Math.min(max_score, parseInt(element.data('score'))))

    noramlized_score = min_score
    normalized_score = Math.min(Math.max(min_score, (score - min_score)/(max_score - min_score)), 1) if max_score - min_score > 0

    labels = d3.range(min_score, max_score, (max_score - min_score) / 4)
    labels.push(max_score)

    color = colors[colors.length - 1]

    # interpolate between the color scales
    # usually we wouldn't want to do this, but it looks strange to point to a spot on the
    # continuous gradient but not have that exact color be reflected in the score
    # should be a better way to do in d3 in this.
    if normalized_score < 1
      scaled = normalized_score * (colors.length - 1)
      floor = Math.floor(scaled)
      remainder = scaled - floor
      color = d3.interpolateRgb(colors[floor], colors[floor+1])(remainder)
      # debugger

    svg = d3.select(element[0])
      .append("svg")
      .attr("width", 940)
      .attr("height", 155)

    defs = svg.append('defs')

    linearGradient = defs.append("linearGradient")
      .attr("id", "linear-gradient")

    colorScale = d3.scale.linear().range(colors)

    linearGradient.selectAll("stop")
        .data( colorScale.range() )
            .enter().append("stop")
            .attr("offset", (d,i) -> i/(colorScale.range().length-1))
            .attr("stop-color", (d) -> d)

    svg.append("rect")
      .attr("width", '940')
      .attr("height", 30)
      .attr("x", 0)
      .attr("y", 125)
      .attr("rx", 4)
      .attr("ry", 4)
      # .attr("stroke-width", 2)
      # .attr("stroke", "#999")
      .style("fill", "url(#linear-gradient)")

    svg.selectAll('labels')
      .data(labels)
      .enter()
      .append('text')
      .style('fill', '#fff')
      .attr("y", 140)
      .attr("x", (d, i) -> i *  920 / (labels.length - 1) + 10)
      .style("text-anchor", (d, i) ->
        if i == 0
          "start"
        else if i == labels.length - 1
          "end"
        else
          "middle"
      )
      .attr("font-family", "sans-serif")
      .attr("font-size", "14px")
      .attr("alignment-baseline", "central")
      .text((d) -> "#{Math.floor(d)} points")

    scoreBox = svg.append("rect")
      .attr("width", 120)
      .attr("height", 100)
      .attr("x", normalized_score * 820)
      .attr("y", 10)
      .attr("rx", 4)
      .attr("ry", 4)
      .attr("stroke-width", 1)
      .attr("stroke", d3.rgb(color).darker())
      .style("fill", color)

    line = d3.svg.line()
             .x((d) -> d.x + normalized_score * 920)
             .y((d) -> d.y + 109)


    scoreTriangle = svg.append("path")
      .datum([{x: 20, y: 0}, {x: 10, y:15}, {x: 0, y: 0}])
      .attr("fill", color)
      .attr("stroke-width", 1)
      .attr("stroke", d3.rgb(color).darker())
      .attr("d", line)

    scoreText = svg.append("text")
      .attr("x", normalized_score * 820 + 61)
      .attr("y", 70)
      .attr("font-family", "sans-serif")
      .attr("font-size", "66px")
      .attr("fill", "#fff")
      .attr("text-anchor", "middle")
      .text(score)

    scoreOf = svg.append("text")
      .attr("x", normalized_score * 820 + 60)
      .attr("y", 98)
      .attr("font-family", "sans-serif")
      .attr("font-size", "14px")
      .attr("fill", "#fff")
      .attr("text-anchor", "middle")
      .text("of #{max_score} points")

    scoreText
      .transition()
      .duration(@transitionTime)
      .attrTween("transform", (d) => d3.interpolateString("translate(-#{normalized_score * 820},0)", "translate(0,0)"))
      .tween("text", (n) ->
        i = d3.interpolateRound(min_score, score)
        (t) -> @textContent = "#{i(t)}")

    scoreOf
      .transition()
      .duration(@transitionTime)
      .attrTween("transform", (d) => d3.interpolateString("translate(-#{normalized_score * 820},0)", "translate(0,0)"))

    scoreBox
      .transition()
      .duration(@transitionTime)
      .attrTween("transform", (d) => d3.interpolateString("translate(-#{normalized_score * 820},0)", "translate(0,0)"))
      .styleTween("fill", (d) -> d3.interpolate(colors[0], color))
      .styleTween("stroke", (d) -> d3.interpolate(d3.rgb(colors[0]).darker(), d3.rgb(color).darker()))

    scoreTriangle
      .transition()
      .duration(@transitionTime)
      .attrTween("transform", (d) => d3.interpolateString("translate(-#{normalized_score * 920 },0)", "translate(0,0)"))
      .styleTween("fill", (d) -> d3.interpolate(colors[0], color))

