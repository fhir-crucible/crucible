
# private methods
daydiff = (first, second) ->
  Math.floor((second-first)/(1000*60*60*24))

weekdiff = (first, second) ->
  Math.floor(daydiff(first,second) / 7)

color = (data, threshold) ->
  colors = ["#bd0026", "#f03b20", "#fd8d3c", "#fecc5c", "#c2e699", "#78c679", "#31a354", "#006837"]
  data.supportedtotal = 0 if !data.supportedtotal
  data.supportedpassed = 0 if !data.supportedpassed
  if data.supportedtotal == 0
    '#bbb'
  else
    colors[Math.floor((data.supportedpassed / data.supportedtotal) * (colors.length-1))]

percentMe = (data) ->
  data.supportedtotal = 0 if !data.supportedtotal
  data.supportedpassed = 0 if !data.supportedpassed
  if data.supportedtotal == 0
    0
  else
    Math.round(data.supportedpassed / data.supportedtotal * 100)

# returns appropriate tool tip for section
tip = d3.tip()
  .attr('class', 'd3-tip')
  .offset([-10, 0])
  .html((d) -> "#{d.date}<br/> #{d.type}:<br>#{d.value.supportedpassed} / #{d.value.supportedtotal} passed (#{percentMe(d.value)}%)")

class Crucible.Doppler

  constructor: (element, data, starburst) ->
    @element = element
    @data = data
    @starburst = starburst
    @starburst.addListeners(this)
    @node_path = []
    @selected_index = 0
    @width = 1000
    @height = 200

    @svg = d3.select(element)
      .append("svg")
      .attr("width", @width)
      .attr("height", @height)


  transitionTo: (nodeName) =>
    setCurrentNode = (nodeName, nodes, node_path) =>
      if nodes.name == nodeName
        @node_path = node_path
        @render()
      else
        if nodes.children
          for c in nodes.children
            new_path = node_path.slice(0) # clone this array
            new_path.push(c.name)
            setCurrentNode(nodeName, c, new_path)

    setCurrentNode(nodeName, @data[0], [])

  render: ->
    margin_left = 65
    margin_top = 50
    cellSize = 14
    threshold = .65
    format = d3.time.format("%Y-%m-%dT%H:%M:%S.%LZ")
    today = new Date()
    next_sunday = (new Date()).setDate(today.getDate() + (7-today.getDay()))
    monthNames =  [today.getFullYear(),'Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
    current_date = next_sunday
    transition_speed = 500
    processed_data = []

    $(@element).removeClass('server-history-loading')

    @svg.selectAll('*')
        .remove()

    d3.select('body')
      .on("keydown", () =>
        if d3.event.key == 'ArrowLeft'
          @selected_index++
          @selected_index = 51 if @selected_index > 51
          switchDate(@selected_index)
        else if d3.event.key == 'ArrowRight'
          @selected_index--
          @selected_index = 0 if @selected_index < 0
          switchDate(@selected_index)
      )


    labels = []
    months = []

    # loop through the rows and explode the data in a way consumable by d3
    # note that it uses the path to the currently selected node in the starburst to pull the proper children
    for row, row_index in @data
      current = row
      for n in @node_path
        for c in current.children
          if c.name == n
            current = c

      if current.children
        for item, index in current.children
          processed_data.push(date: row.date, type: item.name, index: index, value: {total: item.total, passed: item.passed, supportedtotal: item.supportedtotal, supportedpassed: item.supportedpassed})

          # for just the first row, build out the labels in a form consumable by d3
          labels.push(key: item.name, index: index) if !row_index
      else
        processed_data.push(date: row.date, type: current.name, index: 0, value: {total: current.total, passed: current.passed, supportedtotal: current.supportedtotal, supportedpassed: current.supportedpassed})

        # for just the first row, build out the labels in a form consumable by d3
        labels.push(key: current.name, index: 0) if !row_index

    # figure out where to put month names on the chart
    for row in @data
      monthName = monthNames[format.parse(row.date).getMonth()]
      months.push({date: row.date, month: monthName}) if months.length == 0
      months.push({date: row.date, month: monthName}) if months[months.length-1].month != monthName

    # get rid of the first month name if it is close to the second month name
    months.shift() if daydiff(format.parse(months[0].date), format.parse(months[1].date)) < 20

    data_line_middle = @width / 2 - 27
    data_line_width = 150
    date_line = [{x: data_line_middle - data_line_width - 5, y:10},
                 {x: data_line_middle - data_line_width, y:20},
                 {x: data_line_middle + data_line_width, y: 20},
                 {x: data_line_middle + data_line_width + 5, y:10}]

    # TEMP HACK TO MAKE WORK WHEN RUNS EXIST AFTER SUNDAY
    if @data.length > 52
      data_connector_line = [{x: data_line_middle, y:20},
                             {x: data_line_middle, y: 40},
                             {x: @width - 61 - (@selected_index-1) * (3 + cellSize), y: 40},
                             {x: @width - 61 - (@selected_index-1) * (3 + cellSize), y: 80}]
    else
      data_connector_line = [{x: data_line_middle, y:20},
                             {x: data_line_middle, y: 40},
                             {x: @width - 61 - (@selected_index) * (3 + cellSize), y: 40},
                             {x: @width - 61 - (@selected_index) * (3 + cellSize), y: 80}]

    line = d3.svg.line()
            .x((d) -> d.x)
            .y((d) -> d.y)

    @svg.append("path")
       .datum(date_line)
       .style("stroke", "#666")
       .style("fill", "none")
       .style("stroke-width", 2)
       .style("opacity", .5)
       .attr("d", line)

    selected_line = @svg.append("path")
       .datum(data_connector_line)
       .style("stroke", "#666")
       .style("opacity", .5)
       .style("fill", "none")
       .style("stroke-width", 2)
       .attr("d", line)

    # category labels
    @svg.selectAll("label")
       .data(labels)
       .enter()
       .append("text")
       .attr("x", (d) -> margin_left - cellSize / 2 )
       .attr("y", (d) -> margin_top + (2 + d.index) * 14 - 2)
       .style("text-anchor", "end")
       .style("text-transform", "capitalize")
       .attr("font-family", "sans-serif")
       .attr("font-size", "10px")
       .attr('transform', (d) -> "rotate(30 #{margin_left} #{margin_top + (2 + d.index)*14 -2})")
       .text( (d) -> d.key)

    # months along the top
    @svg.selectAll("months")
      .data(months)
      .enter()
      .append("text")
      .attr("x", (d) -> margin_left + (52 - weekdiff(format.parse(d.date), next_sunday)) * (3 + cellSize) )
      .attr("y", (d) -> margin_top + 10 )
      .style("text-transform", "capitalize")
      .attr("font-family", "sans-serif")
      .attr("font-size", "12px")
      .attr("fill", "#aaa")
      .text( (d) -> d.month )

    switchDate = (index) =>

      d = @data[@data.length - index - 1]
      tip.hide()

      if @data.length > 52
        index--

      @selected_index = index

      selected.transition()
          .duration(transition_speed)
          .attr("x", () -> margin_left + (51 - index) * (3 + cellSize)-1)

      @starburst.transitionDate(d)
      # @starburst._setData(d)
      # @starburst._renderChart()


      data_connector_line[2].x = margin_left + (51 -index) * (3 + cellSize) + cellSize / 2
      data_connector_line[3].x = margin_left + (51 - index) * (3 + cellSize) + cellSize / 2
      selected_line
          .datum(data_connector_line)
          .transition()
          .duration(transition_speed)
          .attr("d", line)

    # data
    days = @svg.selectAll(".day")
      .data(processed_data)
      .enter()
      .append("rect")
      .attr("width", cellSize)
      .attr("height", cellSize)
      .attr("x", (d) -> margin_left + (51 - weekdiff(format.parse(d.date), next_sunday)) * (3 + cellSize))
      .attr("y", (d) -> margin_top + (d.index+1) * cellSize)
      .style("fill", (d) -> color(d.value, threshold))
      .style("stroke", "#ccc")
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)
      .on("click", (d) =>
        index = weekdiff(format.parse(d.date), next_sunday)
        if @data.length > 52
          index = index + 1
        switchDate(index)
        return
      )

    # selected date
    # NOTE THAT THIS IS A TEMP FIX FOR WHEN THERE IS A RUN AFTER LAST SUNDAY!
    if @data.length > 52
      selected = @svg.append("rect")
        .attr("x", () => margin_left + (52- @selected_index) * (3 + cellSize)-1 )
        .attr("y", () -> margin_top + cellSize- 1)
        .attr("width", cellSize + 2)
        .attr("height", labels.length * cellSize + 2)
        .style("fill", (d) -> "#fff")
        .style("fill-opacity", .0)
        .style("opacity", .5)
        .style("stroke", "#000")
        .style("stroke-width", 2)
    else
      selected = @svg.append("rect")
        .attr("x", () => margin_left + (52- @selected_index-1) * (3 + cellSize)-1 )
        .attr("y", () -> margin_top + cellSize- 1)
        .attr("width", cellSize + 2)
        .attr("height", labels.length * cellSize + 2)
        .style("fill", (d) -> "#fff")
        .style("fill-opacity", .0)
        .style("opacity", .5)
        .style("stroke", "#000")
        .style("stroke-width", 2)



    # activate tool tip
    @svg.call(tip)
