
# -------------------------- PRIVATE FUNCTIONS ------------------------------ #

# returns appropriate color of section (recursive)
color = (data) ->
  colors = ['#cc0000', '#ff9900', '#e9e913', '#99cc00', '#33cc33']
  colorRanges = [0, 50, 65, 80, 99]

  currentColor = colors[0] 

  if data.total == 0
    '#bbb'
  else
    for range, index in colorRanges
      if percentMe(data) >= range
        currentColor = colors[index]
      else
        break
    currentColor
  
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

  constructor: (element, data) ->
    @element = element
    @data = data
    @nodeMap = {}
    @_constructNodeMap(data)
    @listeners = []

  get: (v) ->
    @[v]

  _renderChart: (->
    unless @get('data')
      return

    # initialize width, height, radius, x, and y
    width = height = @get('size') - 2 * @get('padding')
    radius = Math.min(width, height) / 2
    x = d3.scale.linear().range([0, 2 * Math.PI])
    y = d3.scale.sqrt().range([0, radius])

    # initialize div element for title
    title = d3.select(@get('element')).select("div")

    if @get('data') then d3.select(@get('element')).select("svg").selectAll('g').remove()

    # intitialize svg element with given dimensions
    svg = d3.select(@get('element')).select("svg")
      .append("g")
      .attr("transform", "translate(#{width / 2},#{height / 2 + 10})") # center in svg

    # activate tool tip
    svg.call(tip)

    # define log scale
    logScale = d3.scale.log()

    # define partition layout
    partition = d3.layout.partition()
      .sort(null)
      .value((d) => logScale(Math.max(d.total ,@get('minSize'))))

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
    updateNodeName(node)

    # setup for switching data: stash the old values for transition
    stash = (d) ->
      d.x0 = d.x
      d.dx0 = d.dx
      return

    # when zooming: interpolate the scales
    arcTweenZoom = (d) =>
      xd = d3.interpolate(x.domain(), [d.x, d.x + d.dx])
      yd = d3.interpolate(y.domain(), [d.y, 1])
      yr = d3.interpolate(y.range(), [(if d.y then 20 else 0), radius])
      (d, i) ->
        if i
          (t) -> arc(d)
        else
          (t) ->
            x.domain(xd(t))
            y.domain(yd(t)).range(yr(t))
            arc(d)

    # draw the element paths
    path = svg.datum(root).selectAll("path")
      .data(partition.nodes)
      .enter()
        .append("path")
        .attr("d", arc)
        .style("fill", (d) => color(d))
        .style("stroke", '#fff')
        .attr("class", (d) -> d.name?.replace(/([\s,\&])/g, "_"))
        .on("click", (d) =>
          node = d
          path.transition()
            .duration(@getTransitionSpeed())
            .attrTween("d", arcTweenZoom(d))
          updateNodeName(node)
          $(@listeners).each (i, listener) -> listener.transitionTo(node.name)
          return
        )
        .on('mouseover', tip.show)
        .on('mouseout', tip.hide)
        .each(stash)
    # This allows us to force a node to be selected initially
    # for el in $(@get('element')).find(".#{@get('selectedNode')?.replace(/([\s,\&])/g, "_")}")
    #   el.dispatchEvent(new MouseEvent("click"))
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