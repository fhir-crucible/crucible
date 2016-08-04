
# -------------------------- PRIVATE FUNCTIONS ------------------------------ #

colors = ["#bd0026", "#f03b20", "#fd8d3c", "#fecc5c", "#c2e699", "#78c679", "#31a354", "#006837"]

# returns appropriate color of section (recursive)
color = (data, threshold) ->
  if data.total == 0
    '#bbb'
  else
      colors[Math.floor((data.passed / data.total) * (colors.length-1))]
  # if data.total == 0
  #   '#bbb'      # gray
  # else if data.passed / data.total >= threshold
  #   '#417505'   # green
  # else
  #   '#800010'   # red

# returns appropriate opacity of a failed section
opacity = (data) ->
  1
  # d3.scale.linear()
  #   .domain([.5,1])
  #   .range([.4,1])(Math.max(data.passed, (data.total - data.passed)) / data.total)

# returns percent passing of a section
percentMe = (data) ->
  if data.total == 0
    0
  else
    Math.round(data.passed / data.total * 100)

# returns appropriate tool tip for section
tip = d3.tip()
  .attr('class', 'd3-tip')
  .offset([-10, 0])
  .html((d) -> "#{d.name}:<br>#{d.passed} / #{d.total} passed (#{percentMe(d)}%)")

class Crucible.Starburst
  nodeMap: {}
  size: 350
  padding: 5
  threshold: 0.65
  showHeader: true
  selectedNode: "FHIR"
  minSize: 10
  animationTransition: 1000
  animationTransitionTmp: null

  constructor: (element, data, extended = false) ->
    @element = element
    @data = data
    @nodeMap = {}
    @_constructNodeMap(data)
    @listeners = []
    @extended = extended

  get: (v) ->
    @[v]

  _setData: (data) -> 
    @['data'] = data
    set_current_node = (node) =>
      if @current_node.name == node.name
        @current_node = node
      else
        set_current_node(child) for child in node.children if node.children

    set_current_node(data) if @current_node

  _renderChart: (->
    unless @get('data')
      return

    attachParents = (node) ->
      return unless node.children
      for child in node.children
        child.parent = node
        attachParents(child)

    attachParents(@data)

    # initialize width, height, radius, x, and y
    width = height = @get('size') - 2 * @get('padding')
    width = 1000 if @get('extended')
    radius = Math.min(width, height) / 2
    x = d3.scale.linear().range([0, 2 * Math.PI])
    y = d3.scale.sqrt().range([0, radius])

    # initialize div element for title
    title = d3.select(@get('element')).select("div")

    if @get('data') then d3.select(@get('element')).select("svg").selectAll('g').remove()

    # intitialize svg element with given dimensions
    svg = d3.select(@get('element')).select("svg")
      .attr("viewBox","0 0 #{width} #{height}")
      .append("g")

      # .attr("transform", "translate(#{width / 2},#{height / 2})") # center in svg

    # activate tool tip
    svg.call(tip)

    # define log scale
    logScale = d3.scale.log()

    # define partition layout
    partition = d3.layout.partition()
      .sort(null)
      .value((d) => 1)# logScale(Math.max(d.total ,@get('minSize'))))

    # define arc angles and radii
    arc = d3.svg.arc()
      .startAngle((d) -> Math.max(0, Math.min(2 * Math.PI, x(d.x))))
      .endAngle((d) -> Math.max(0, Math.min(2 * Math.PI, x(d.x + d.dx))))
      .innerRadius((d) -> Math.max(0, y(d.y)))
      .outerRadius((d) -> Math.max(0, y(d.y + d.dy)))

    # updates node name text element
    updateNodeName = (d) ->
      title.html("#{d.name}:<p>#{d.passed} / #{d.total} passed (#{percentMe(d)}%)</p>")

    # define root, initialize node to be the root, and update node name
    root = @get('data')
    node = root
    node = @current_node if @current_node
    previous_node = root

    # setup for switching data: stash the old values for transition
    stash = (d) ->
      d.x0 = d.x
      d.dx0 = d.dx
      return

    max_depth = 5

    # when zooming: interpolate the scales
    arcTweenZoom = (c) =>
      xd = d3.interpolate(x.domain(), [c.x, c.x + c.dx])
      yd = d3.interpolate(y.domain(), [c.y, 1])
      (d, i) ->
        newY = d.y
        newDy = d.dy
        if d.depth == c.depth
          newY = 0
          newDy = 1/max_depth
        else
          heights = (1 - 1/max_depth) / (max_depth - c.depth)
          newDy = heights
          newY = 1/max_depth + (d.depth - c.depth - 1) * heights

        ny = d3.interpolate(d.y, newY)
        ndy = d3.interpolate(d.dy, newDy)
        if i
          (t) ->
            d.y = ny(t)
            d.dy = ndy(t)
            arc(d)
        else
          (t) ->
            x.domain(xd(t))
            arc(d)

    percentage = svg.append("text")
      .attr("x", (d, i) -> width/2)
      .attr("y", (d, i) -> height/2+18)
      .attr("font-family", "sans-serif")
      .attr("font-size", "60px")
      .attr("fill", "#333")
      .attr("text-anchor", "middle")
      .text( (d) => "#{percentMe(@get('data'))}%")

    if @get("extended")
      node_name = svg.append("text")
        .attr("x", (d, i) -> width/2)
        .attr("y", (d, i) -> height/2-40)
        .attr("font-family", "sans-serif")
        .attr("font-size", "16px")
        .attr("fill", "#333")
        .attr("text-anchor", "middle")
        .text( (d) =>
          if @current_node
            @current_node.name
          else
            @data.name)

      svg.append("text")
        .attr("x", (d, i) -> width/2)
        .attr("y", (d, i) -> height/2+45)
        .attr("font-family", "sans-serif")
        .attr("font-size", "12px")
        .attr("fill", "#999")
        .attr("text-anchor", "middle")
        .text( 'PASSING')
    
    # draw the element paths
    path = svg.datum(root).selectAll("path")
      .data(partition.nodes)
      .enter()
        .append("path")
        .attr("transform","translate(#{width/2},#{height/2})")
        .attr("d", arc)
        .style("fill", (d) => color(d, @get('threshold')))
        .style("stroke", '#fff')
        .style("opacity", (d) => 0 unless d.depth)
        .attr("class", (d) -> d.name?.replace(/([\s,\&])/g, "_"))
        .on("click", (d) =>

          @current_node = d

          return unless d.parent

          previous_node = node
          goingUp = (node.name == d.name)
          if goingUp
            node = node.parent
            @current_node = node
          else
            node = d

          path.transition()
            .duration(@getTransitionSpeed())
            .attrTween("d", arcTweenZoom(node))
            .styleTween("opacity", (n) =>

              return d3.interpolate(0,0) if n.depth < node.depth and !goingUp
              return d3.interpolate(1,0) if n.depth == node.depth and !goingUp and previous_node.name != n.name
              return d3.interpolate(0,1) if n.depth-1 == node.depth and goingUp

            )
            .each("end", (d, i) -> renderLabels(node) if !i)
          
          fancyLabels.selectAll("*").transition()
             .duration(@getTransitionSpeed()/2)
             .styleTween("opacity", (n) -> d3.interpolate(1,0))

          percentage.transition()
            .duration(@getTransitionSpeed())
            .tween("text", (n) -> 
               i = d3.interpolateRound(percentMe(previous_node), percentMe(node))
               (t) -> @textContent = "#{i(t)}%")#"#{Math.round(i(t))}%")

          if @get("extended")
            node_name.text("#{node.name}")
          
          updateNodeName(node)
          $(@listeners).each (i, listener) -> listener.transitionTo(node.name) #todo clean this up
          return
        )
        .on('mouseover', tip.show)
        .on('mouseout', tip.hide)
        .each(stash)

    if @current_node
      path.transition()
        .duration(0)
        .attrTween("d", arcTweenZoom(@current_node))
        .styleTween("opacity", (n) =>
           return d3.interpolate(1,0) if n.depth <= @current_node.depth
        )
        .each('end', (d) => renderLabels(@current_node))

      # percentage.transition()
      #   .duration(.1)
      #   .tween("text", (n) => 
      #      (t) -> @textContent = "#{percentMe(@current_node)}")

    # This allows us to force a node to be selected initially
    # for el in $(@get('element')).find(".#{@get('selectedNode')?.replace(/([\s,\&])/g, "_")}")
    #   el.dispatchEvent(new MouseEvent("click"))

    if @get("extended")
      svg.selectAll(".legend")
        .data(colors)
        .enter()
        .append("rect")
        .attr("width", 14)
        .attr("height", 14)
        .attr("x", (d, i) -> width - 22 - colors.length * 15 + (i * 15))
        .attr("y", (d) -> height - 18)
        .style("fill", (d) -> d)

      svg.append("rect")
        .attr("width", 14)
        .attr("height", 14)
        .attr("x", (d) -> width - 18)
        .attr("y", (d) -> height - 18)
        .style("fill", (d) -> '#ccc')

      legendLabels = ['0%', '50%', '100%']
      svg.selectAll('.legendLabels')
        .data(legendLabels)
        .enter()
        .append("text")
        .attr("x", (d, i) -> width - 22 - colors.length * 15 + 43*i)
        .attr("y", (d, i) -> height - 22)
        .attr("font-family", "sans-serif")
        .attr("font-size", "12px")
        .attr("fill", "#333")
        .text( (d) => d)

      svg.append("text")
        .attr("x", () -> width - 18)
        .attr("y", (d, i) -> height - 22)
        .attr("font-family", "sans-serif")
        .attr("font-size", "8px")
        .attr("fill", "#333")
        .text( () => "N/A")

      svg.append("text")
        .attr("x", () -> width - 225)
        .attr("y", (d, i) -> height - 6)
        .attr("font-family", "sans-serif")
        .attr("font-size", "16px")
        .attr("fill", "#333")
        .text( () => "% Passing")

    fancyLabels = svg.append("g")

    renderLabels = (n) =>
      return unless @get("extended")

      fancyLabels.selectAll("*").remove()

      calculateX = (d) =>
        Math.sin(x(d.x + (d.dx/2))) * 90 + width/2

      calculateY = (d) =>
        height/2 - Math.cos(x(d.x + (d.dx/2))) * 90

      labels = n.children

      leftIndex = 0
      rightIndex = 0
      for item in labels
        if x(item.x + (item.dx / 2)) > Math.PI + .1
          item.indexY = leftIndex++
          item.labelY = 20 + leftIndex * 30 
          item.labelX = 150
          item.percentX = item.labelX + 100
          item.text_anchor = "end"
        else
          item.indexY = rightIndex++
          item.labelY = 20 + rightIndex * 30
          # item.labelX = width - 150
          item.labelX = width / 2 + Math.sin(Math.PI * item.labelY / height) * (radius * .6) + 210
          item.percentX = item.labelX - 35
          item.lineX = item.labelX - 55
          item.text_anchor = "start"
          item.boxX = item.labelX - 60

       # looping back over to put the left labels in descending order
       for item in labels
         if item.labelX == 150
           item.indexY = leftIndex - item.indexY
           item.labelY = 20 + item.indexY * 30
           item.labelX = width / 2 - Math.sin(Math.PI * item.labelY / height) * (radius * .6) - 210
           item.percentX = item.labelX + 35
           item.lineX = item.labelX + 55
           item.boxX = item.labelX + 10

       fancyLabels.selectAll("label")
         .data(labels)
         .enter()
         .append("text")
         .attr("x", (d, i) -> d.labelX)
         .attr("y", (d, i) -> d.labelY)
         .style("text-anchor", (d) -> d.text_anchor)
         .style("text-transform", "capitalize")
         .attr("font-family", "sans-serif")
         .attr("font-size", "18px")
         .text( (d) -> "#{d.name}")

       for item in labels
         fancyLabels.append("line")
          .attr("x1", item.lineX)
          .attr("y1", item.labelY - 8)
          .attr("x2", calculateX(item))
          .attr("y2", calculateY(item))
          # .attr("opacity", .5)
          .attr("stroke-width", 1)
          .attr("stroke", "black")

         fancyLabels.append('rect')
          .attr("width", 50)
          .attr("height", 20)
          .attr("x", item.boxX)
          .attr("y", item.labelY - 17)
          .attr("rx", 5)
          .attr("ry",5)
          .style("fill", color(item))

       fancyLabels.selectAll("percent")
         .data(labels)
         .enter()
         .append("text")
         .attr("x", (d, i) -> d.percentX)
         .attr("y", (d, i) -> d.labelY-2)
         .style("text-anchor", "middle")
         .style("text-transform", "capitalize")
         .attr("font-family", "sans-serif")
         .attr("font-size", "14px")
         .attr("fill", "#fff")
         .text( (d) -> "#{percentMe(d)}%")



       circles = fancyLabels.selectAll("circle")
        .data(labels)
        .enter()
        .append("circle")
        .style("fill", color)
        .style("stroke", "#000")
        .attr("cx", calculateX)
        .attr("cy", calculateY)
        .attr("r", 3)

    if @get('extended')
      renderLabels(node)


    return
  )#.observes('data').on('didInsertElement')

  addListeners: (listeners) ->
    @listeners = @listeners.concat(listeners)

  addListener: (listener) ->
    @listeners.push(listener)

  getTransitionSpeed: ->
    speed = @animationTransition
    if @animationTransitionTmp?
      speed = @animationTransitionTmp 
      @animationTransitionTmp = null
    speed

  transitionTo: (name, speed) ->
    @selectedNode = name
    @animationTransitionTmp = speed
    @_updatePlot()

  _constructNodeMap: (data) ->
    @nodeMap[data.name] = data
    return unless data.children
    for child in data.children
      @_constructNodeMap(child)

  _updatePlot: (->
    # This allows the containing element to change what's selected
    for el in $(@get('element')).find(".#{@get('selectedNode')?.replace(/([\s,\&])/g, "_")}")
      el.dispatchEvent(new MouseEvent("click"))
  )#.observes('selectedNode')
