
# private methods
daydiff = (first, second) ->
  Math.round((second-first)/(1000*60*60*24))

weekdiff = (first, second) ->
  52 - daydiff(first,second) / 7

color = (data, threshold) ->
  if data == null
    '#ddd'      # gray
  else if data >= threshold
    '#417505'   # green
  else
    '#800010'   # red

opacity = (data) ->
  if data == null || data == 0
    1
  else
    d3.scale.linear()
      .domain([.5,1])
      .range([.4,1])(data)

class Crucible.Doppler

  constructor: (element, data) ->
    @element = element
    @data = data

  render: ->
    margin = 65
    width = 1000
    height = 136
    cellSize = 14
    threshold = .65
    percent = d3.format(".1%")
    format = d3.time.format("%Y-%m-%d")
    monthNames =  [(new Date()).getFullYear(),'Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

    svg = d3.select(@element)
      .append("svg")
      .attr("width", width)
      .attr("height", height)

    processed_data = []
    labels = []
    months = []

    # get a list of labels
    # process data into a form consumable by d3
    for key, index in Object.keys(@data[0])
      if index > 0
        labels.push(key: key, index: index)
        for row in @data
          processed_data.push(date: row.date, type: key, index: index, value: row[key])

    # figure out where to put month names on the chart
    for row in @data
      monthName = monthNames[format.parse(row.date).getMonth()]
      if !months.length || months[0].month != monthName
        months.unshift({date: row.date, month: monthName})
      else
        months[0].date = row.date;

    # get rid of the first month name if it is close to the second month name
    months.shift() if daydiff(format.parse(months[months.length-1].date), format.parse(months[months.length-2].date) < 7)

    # category labels
    svg.selectAll("label")
       .data(labels)
       .enter()
       .append("text")
       .attr("x", (d) -> margin - cellSize / 2 )
       .attr("y", (d) -> (1 + d.index) * 14 - 2)
       .style("text-anchor", "end")
       .style("text-transform", "capitalize")
       .attr("font-family", "sans-serif")
       .attr("font-size", "11px")
       .text( (d) -> d.key)

    # months along the top
    svg.selectAll("months")
      .data(months)
      .enter()
      .append("text")
      .attr("x", (d) -> margin + weekdiff(format.parse(d.date), new Date()) * (3 + cellSize) )
      .attr("y", (d) -> 10 )
      .style("text-transform", "capitalize")
      .attr("font-family", "sans-serif")
      .attr("font-size", "12px")
      .attr("fill", "#aaa")
      .text( (d) -> d.month )

    # data
    svg.selectAll(".day")
      .data(processed_data)
      .enter()
      .append("rect")
      .attr("width", cellSize)
      .attr("height", cellSize)
      .attr("x", (d) -> margin + weekdiff(format.parse(d.date), new Date()) * (3 + cellSize))
      .attr("y", (d) -> d.index * cellSize)
      .style("fill", (d) -> color(d.value, threshold))
      .style("stroke", "#ccc")
      .style("opacity", (d) -> opacity(d.value))
      .append("title")
      .text((d) -> d.date + ' - ' + d.type + ' - ' + d.value )
