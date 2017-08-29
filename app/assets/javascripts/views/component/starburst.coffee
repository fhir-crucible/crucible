
# -------------------------- PRIVATE FUNCTIONS ------------------------------ #

colors = ["#bd0026", "#f03b20", "#fd8d3c", "#fecc5c", "#c2e699", "#78c679", "#31a354", "#006837"]

# returns appropriate color of section (recursive)
color = (data) ->
  if data.total == 0
    '#bbb'
  else
      colors[Math.floor((data.passed / data.total) * (colors.length-1))]

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
  showHeader: true
  selectedNode: "FHIR"
  minSize: 10
  animationTransition: 1000
  animationTransitionTmp: null

  constructor: (element, data, extended = false) ->
    @element = element
    @_processData(data)
    @nodeMap = {}
    @_constructNodeMap(data)
    @listeners = []
    @extended = extended
    @zoomable = extended || $(element).parent().find('a').length == 0

    # if on front page, a click to the starburst should go to the server page
    if !@zoomable
      $(element).on("click", () ->
        window.location = $(@).parent().find('a').attr('href')
      )

  get: (v) ->
    @[v]

  set: (v, d) ->
    @[v] = d

  _processData: (data) ->

    @set('data', data)

    # attach parents to a given node so we can move back up the starburst
    # also determine the depth of the whole tree
    processNodes = (node, depth) ->
      return depth unless node.children

      new_depth = depth
      for child in node.children
        child.parent = node
        new_depth = Math.max(processNodes(child, depth+1), new_depth)

      return new_depth

    @max_depth = processNodes(data, 1)
    @_constructNodeMap(data)

  _renderChart: ()->
    unless @get('data')
      return

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

    # activate tool tip
    svg.call(tip)

    # define log scale
    logScale = d3.scale.log()

    # define partition layout
    # The value used to be the following
    # logScale(Math.max(d.total ,@get('minSize'))))
    # but changed it to just being 1 so the starburst structure stays the same
    partition = d3.layout.partition()
      .sort(null)
      .value((d) => 1)

    # define arc angles and radii
    arc = d3.svg.arc()
      .startAngle((d) -> Math.max(0, Math.min(2 * Math.PI, x(d.x))))
      .endAngle((d) -> Math.max(0, Math.min(2 * Math.PI, x(d.x + d.dx))))
      .innerRadius((d) -> Math.max(0, y(d.y)))
      .outerRadius((d) -> Math.max(0, y(d.y + d.dy)))

    # updates node name text element
    updateNodeName = (d) ->
      title.html("#{d.name}:<p>#{d.passed} / #{d.total} passed (#{percentMe(d)}%)</p>")

    # when zooming: interpolate the scales
    arcTweenZoom = (c) =>
      xd = d3.interpolate(x.domain(), [c.x, c.x + c.dx])
      yd = d3.interpolate(y.domain(), [c.y, 1])
      (d, i) =>
        newY = d.y
        newDy = d.dy
        if d.depth == c.depth
          newY = 0
          newDy = 1/@get('max_depth')
        else
          heights = (1 - 1/@get('max_depth')) / (@get('max_depth') - c.depth)
          newDy = heights
          newY = 1/@get('max_depth') + (d.depth - c.depth - 1) * heights

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

    # set the opacity of while zooming
    opacityTweenZoom = (c) =>
      if c.depth > @nodeMap[@selectedNode].depth or (c.name == @selectedNode and !@nodeMap[@selectedNode].children)
        d3.interpolate(c.node_opacity, c.node_opacity = 1)
      else
        d3.interpolate(c.node_opacity, c.node_opacity = 0)

    # caled when a node is selected by mouse or when it is being transitioned to from another node
    selectNode = (new_node) =>

      @selectedNode = new_node.name

      @starburst_path.transition()
        .duration(@getTransitionSpeed())
        .attrTween("d", arcTweenZoom(new_node))
        .styleTween("opacity", opacityTweenZoom)
        .each("end", (d, i) -> renderLabels(new_node) if !i)

      fancyLabels.selectAll("*").transition()
         .duration(@getTransitionSpeed()/2)
         .styleTween("opacity", (n) -> d3.interpolate(1,0))

      @center_percentage.transition()
        .duration(@getTransitionSpeed())
        .tween("text", (n) ->
           i = d3.interpolateRound(n.center_percentage, n.center_percentage = percentMe(new_node))
           (t) -> @textContent = "#{i(t)}%")#"#{Math.round(i(t))}%")

      if @get("extended")
        node_name.text("#{new_node.name}")
      
      updateNodeName(new_node)

    @center_percentage = svg.selectAll("text")
      .data([@get('data')])
      .enter()
      .append("text")
      .attr("x", (d, i) -> width/2)
      .attr("y", (d, i) -> height/2+18)
      .attr("font-family", "sans-serif")
      .attr("font-size", "60px")
      .attr("fill", "#333")
      .attr("text-anchor", "middle")
      .text( (d) => "#{d.center_percentage = percentMe(d)}%")

    if @get("extended")
      node_name = svg.append("text")
        .attr("x", (d, i) -> width/2)
        .attr("y", (d, i) -> height/2-40)
        .attr("font-family", "sans-serif")
        .attr("font-size", "16px")
        .attr("fill", "#333")
        .attr("text-anchor", "middle")
        .text(@data.name)

      svg.append("text")
        .attr("x", (d, i) -> width/2)
        .attr("y", (d, i) -> height/2+45)
        .attr("font-family", "sans-serif")
        .attr("font-size", "12px")
        .attr("fill", "#999")
        .attr("text-anchor", "middle")
        .text( 'PASSING')
    else
      svg.append("text")
        .attr("x", (d, i) -> width/2)
        .attr("y", (d, i) -> height/2+50)
        .attr("font-family", "sans-serif")
        .attr("font-size", "20px")
        .attr("fill", "#999")
        .attr("text-anchor", "middle")
        .text( @get('data').fhir_sequence )
    
    # draw the element paths
    @starburst_path = svg.datum(@get('data')).selectAll("path")
      .data(partition.nodes)
      .enter()
        .append("path")
        .attr("transform","translate(#{width/2},#{height/2})")
        .attr("d", arc)
        .style("fill", (d) => color(d))
        .style("stroke", '#fff')
        .style("opacity", (d) =>
          if d.depth
            d.node_opacity = 1
          else
            d.node_opacity = 0
        )
        .attr("class", (d) -> d.name?.replace(/([\s,\&])/g, "_"))
        .on("click", (d) =>
          return if !d.parent || !@get('zoomable')
          if @selectedNode == d.name and d.parent
            selectNode(d.parent)
          else
            selectNode(d)

          $(@listeners).each (i, listener) => listener.transitionTo(@selectedNode) #todo clean this up
        )
        .on("synchronize", selectNode)
        .on('mouseover', tip.show)
        .on('mouseout', tip.hide)

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

      labels = n.children

      # if no children, force a label for the current
      labels = [n] unless labels

      calculateX = (d) =>
        # if no children, it must mean we are on a leaf, so have the label point to the middle of the starburst
        if !n.children
          width/2
        else
          Math.sin(x(d.x + (d.dx/2))) * 90 + width/2

      calculateY = (d) =>
        # if no children, it must mean we are on a leaf, so have the label point to the middle of the starburst
        if !n.children
          height/2
        else
          height/2 - Math.cos(x(d.x + (d.dx/2))) * 90

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

       nameLabel = fancyLabels.selectAll("label")
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

       line = fancyLabels.selectAll('line')
         .data(labels)
         .enter()
         .append("line")
         .attr("x1", (d) -> d.lineX)
         .attr("y1", (d) -> d.labelY - 8)
         .attr("x2", calculateX)
         .attr("y2", calculateY)
         .attr("stroke-width", 1)
         .attr("stroke", "black")

       @labels_background = fancyLabels.selectAll('rect')
         .data(labels)
         .enter()
         .append('rect')
         .attr("width", 50)
         .attr("height", 20)
         .attr("x", (d) -> d.boxX)
         .attr("y", (d) -> d.labelY - 17)
         .attr("rx", 5)
         .attr("ry",5)
         .style("fill", (d) -> d.labels_background_color = color(d))

       @labels_circles = fancyLabels.selectAll("circle")
         .data(labels)
         .enter()
         .append("circle")
         .style("stroke", "#000")
         .attr("cx", calculateX)
         .attr("cy", calculateY)
         .attr("r", 3)
         .style("fill", (d) -> d.labels_circles_color = color(d))

       @labels_text = fancyLabels.selectAll("percent")
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
         .text( (d) -> "#{d.labels_percent = percentMe(d)}%")

       # animate the labels
       # this is for flair and can be removed if they are too distracting
       
       for item in [nameLabel, @labels_text,@labels_background]
         item.style("opacity", 0)
           .transition()
           .duration(@getTransitionSpeed()/2)
           .attrTween("transform", (d) => translateBy = 30; translateBy = -30 if d.labelX < width/2; d3.interpolateString("translate(#{translateBy},0)", "translate(0,0)"))
           .styleTween("opacity", (n) => d3.interpolate(0,1))
           .delay((d) => d.indexY * 75)

       line.attr("stroke-dasharray", "400 400")
         .attr("stroke-dashoffset", -400)
         .transition()
         .duration(@getTransitionSpeed()/2)
         .attr("stroke-dashoffset", 0)
         .delay((d) => 100 + d.indexY * 75)

       @labels_circles.style("opacity", 0)
         .transition()
         .duration(@getTransitionSpeed()/2)
         .styleTween("opacity", (n) => d3.interpolate(0,1))
         .delay((d) => d.indexY * 75)

    if @get('extended')
      renderLabels(@get('data'))

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

  transitionDate: (data) =>

    data_lookup = {}
    build_data_lookup = (d) ->
      data_lookup[d.name] = d
      return unless d.children
      for child in d.children
        build_data_lookup(child)

    build_data_lookup(data)

    @starburst_path.transition()
      .duration(@getTransitionSpeed())
      .styleTween("fill", (n) =>
        new_n = data_lookup[n.name]
        new_n = {total: 0, passed: 0} if !new_n
        interpolate = d3.interpolateRgb(color(n), color(new_n))
        n.total = new_n.total
        n.passed = new_n.passed
        interpolate
      )

    @labels_background.transition()
      .duration(@getTransitionSpeed())
      .styleTween("fill", (n) =>
        new_n = data_lookup[n.name]
        d3.interpolateRgb(n.labels_background_color, n.labels_background_color = color(new_n))
      )

    @labels_circles.transition()
      .duration(@getTransitionSpeed())
      .styleTween("fill", (n) =>
        new_n = data_lookup[n.name]
        d3.interpolateRgb(n.labels_circles_color, n.labels_circles_color = color(new_n))
      )

    @labels_text.transition()
      .duration(@getTransitionSpeed())
      .tween("text", (n) ->
        i = d3.interpolateRound(n.labels_percent, n.labels_percent = percentMe(n))
        (t) -> @textContent = "#{i(t)}%")

    @center_percentage.transition()
      .duration(@getTransitionSpeed())
      .tween("text", (n) ->
        i = d3.interpolateRound(n.center_percentage, n.center_percentage = percentMe(n))
        (t) -> @textContent = "#{i(t)}%")

  _constructNodeMap: (data) ->
    @nodeMap[data.name] = data
    return unless data.children
    for child in data.children
      @_constructNodeMap(child)

  _updatePlot: (->
    # This allows the containing element to change what's selected
    for el in $(@get('element')).find(".#{@get('selectedNode')?.replace(/([\s,\&])/g, "_")}")
      el.dispatchEvent(new Event("synchronize"))
  )#.observes('selectedNode')
