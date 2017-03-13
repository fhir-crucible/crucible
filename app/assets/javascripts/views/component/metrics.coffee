$(document).ready( ->
  new Crucible.CalendarChart()
  new Crucible.BarChart()
  new Crucible.LineChart()
)

class Crucible.CalendarChart
  width: 1150
  height:180
  cellSize: 20

  format: d3.time.format("%Y-%m-%d")

  constructor: ->
    @element = '.calendar-chart'
    @loadData()

  loadData: =>
    $.getJSON('/calendar_data')
      .success((data) =>
        if data.tests_by_date
          @data = []
          data.tests_by_date.forEach( (d) =>
            @data.push( {
              date: new Date(d._id.year, 0, d._id.day),
              count: d.count
            })
          )
          @renderChart(@data)
      )

  getWeek: (d) =>
    if d.getFullYear() == @startDate.getFullYear()
      return d3.time.weekOfYear(d) - d3.time.weekOfYear(@startDate)
    else
      weekDay = d.getDay()
      days = d3.time.dayOfYear( d ) + 1 + d3.time.dayOfYear(new Date( @endDate.getFullYear(), 0, 0)) - d3.time.dayOfYear(@startDate)
      week = Math.floor((days + @startDate.getDay() ) / 7)
      return week

  monthPath: (t0) =>
    t1 = new Date(t0.getFullYear(), t0.getMonth() + 1, 0)
    d0 = t0.getDay()
    w0 = @getWeek(t0)
    d1 = t1.getDay()
    w1 = @getWeek(t1)
    return "M" + (w0 + 1) * @cellSize + "," + d0 * @['cellSize'] + "H" + w0 * @['cellSize'] + "V" + 7 * @['cellSize'] + "H" + w1 * @['cellSize'] + "V" + (d1 + 1) * @['cellSize'] + "H" + (w1 + 1) * @['cellSize'] + "V" + 0 + "H" + (w0 + 1) * @['cellSize'] + "Z"

  renderChart: (data) =>
    now = new Date()
    @startDate = new Date( now.getFullYear() - 1, now.getMonth()+1, 1)
    @endDate = new Date( now.getFullYear(), now.getMonth() + 1, 1)

    color = d3.scale.quantize()
    .domain(d3.extent(data, (d) => return Math.log(d.count) ))
    .range(d3.range(9).map( (d) => return "q" + d + "-9" ))

    svg = d3.select(@element).selectAll("svg")
      .data([now])
      .enter().append("svg")
      .attr("width", @['width'])
      .attr("height", @['height'])
      .attr("class", "YlOrBr")
        .append("g")
      .append("g")
        .attr("transform", "translate(" + ((@['width'] - @['cellSize'] *53) / 2) + "," + (@['height'] - @['cellSize'] * 7 - 25) + ")")

    dates = d3.time.days(@startDate, @endDate)
    calendar_data = {}
    for date in dates
      do (date) ->
        calendar_data[d3.time.format("%Y-%m-%d")(date)] = 0

    for d in data
      do (d) ->
        calendar_data[d3.time.format("%Y-%m-%d")(d.date)] = d.count

    rect = svg.selectAll(".day")
      .data( (d) => return d3.time.days(@startDate, @endDate) )
      .enter().append("rect")
        .attr("width", @cellSize)
        .attr("height", @cellSize)
        .attr("x", (d) => return @getWeek(d) * @['cellSize'])
        .attr("y", (d) => return d.getDay() * @['cellSize'])
        .attr("class", (d) =>
          val = Math.log(calendar_data[d3.time.format("%Y-%m-%d")(d)])
          c = color(val)
          if( (c == undefined || c == "q0-9") and val >= 0 )
            c = "q1-9"
          c = "q0-9" if !c
          return "day " + c
        )
        .append("svg:title")
          .text( (d) => @format(d) + ": " +  calendar_data[@format(d)] + " test runs")
        .datum(@format)

    svg.selectAll(".month")
      .data( (d) => return d3.time.months(@startDate, @endDate) )
      .enter().append("path")
      .attr("class", "month")
      .attr("d", @monthPath)

    weekDays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
    month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

    titlesDays = svg.selectAll('.titles-day')
    .data(weekDays)
    .enter().append('g')
    .attr('class', 'titles-day')
    .attr('transform', (d, i) => return 'translate(-10,' + ( 15 + (@height-35)/ 7 * i) + ')' )
    
    titlesDays.append('text')
    .attr('class', (d,i) => return weekDays[i] )
    .style('text-anchor', 'end')
    .attr('dy', '-.25em')
    .text( (d, i) =>  return weekDays[i] ) 

    titlesMonth = svg.selectAll('.titles-month')
    .data(month)
    .enter().append('g')
    .attr('class', 'titles-month')
    .attr('transform', (d, i) => return 'translate(' + (( (  ( (i - @endDate.getMonth() + 12) % 12) + 1) * (@['cellSize'] * 53 /12) )-30) + ',' + (@height-25) + ')' )

    titlesMonth.append('text')
    .attr('class', (d,i) => return month[i] )
    .style('text-anchor', 'end')
    .text( (d,i) => return month[i] )

class Crucible.BarChart
  
  constructor: ->
    @element = '.bar-chart'
    @margin = {top: 0, right: 20, bottom: 70, left: 70}
    @width = 538 - @margin.left - @margin.right
    @height = 300 - @margin.top - @margin.bottom

    @loadData()

  loadData: =>
    $.getJSON('/bar_chart_data')
      .success((data) =>
        @data = data['test_frequency']
        @renderChart(@data)
      )

  renderChart: (data) =>
    x = d3.scale.ordinal().rangeRoundBands([0, @width], .05)
    y = d3.scale.linear().range([@height, 0])
    
    xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")

    yAxis = d3.svg.axis()
    .scale(y)
    .orient("left")
    .ticks(10)

    svg = d3.select(".bar-chart").append("svg")
    .attr("width", @width + @margin.left + @margin.right)
    .attr("height", @height + @margin.top + @margin.bottom)
      .append("g")
      .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")

    prettyPrint = (name) => return name.replace("argonaut","Argonaut ").replace("test", "").replace("_", " ").replace("dataaccessframework","DAF ")
    x.domain(data.map((d) => return  prettyPrint(d._id) ))
    y.domain([0, d3.max(data, (d) => return d.count )])

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + @height + ")")
      .call(xAxis)
    .selectAll("text")
      .style("text-anchor", "end")
      .attr("dx", "-.8em")
      .attr("dy", "-.55em")
      .attr("transform", "rotate(-45)" )

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
    .append("text")
      .attr("class", "y-label")
      .attr("transform", "rotate(-90)")
      .attr("y",-45)
      .attr("x", -@height/2)
      .style("text-anchor", "middle")
      .text("Test Runs")

    svg.selectAll("bar")
      .data(data)
    .enter().append("rect")
      .style("fill", (d,i) => 
        if i%2 == 0 
          return "rgb(254,153,41)"
        else
          return "rgb(153,52,4)"
      )
      .attr("x", (d) => return x( prettyPrint(d._id) ))
      .attr("width", x.rangeBand())
      .attr("y", (d) => return y(d.count))
      .attr("height", (d) => return @height - y(d.count) )


class Crucible.LineChart

  constructor: ->
    @element = '.line-chart'
    @margin = {top: 0, right: 20, bottom: 72, left: 50}
    @width = 538 - @margin.left - @margin.right
    @height = 300 - @margin.top - @margin.bottom

    @loadData()

  loadData: =>
    $.getJSON('/calendar_data')
      .success((data) =>
        date_dict = {}
        data['tests_by_date'].forEach( (d) =>
          date_dict[ new Date(d._id.year, 0, d._id.day)] = d.count
        )
        month_data = []
        now = new Date()
        d3.time.days(new Date().setMonth(now.getMonth() - 2), now).forEach( (date) =>
          count = 0
          if date_dict[date]
            count = date_dict[date]
          month_data.push({
            date:date,
            count:count
          })
        )
        @renderChart(month_data)
      )

  renderChart: (month_data) =>
    parseDate = d3.time.format("%d-%b-%y").parse
    x = d3.time.scale().range([0, @width])
    y = d3.scale.linear().range([@height, 0])

    xAxis = d3.svg.axis().scale(x)
    .orient("bottom").ticks(5)

    yAxis = d3.svg.axis()
     .scale(y)
     .orient("left")
     .ticks(5)

    valueline = d3.svg.line()
    .x( (d) => return x(d.date) )
    .y( (d) => return y(d.count) )

    svg = d3.select(@element)
    .append("svg")
      .attr("width", @width + @margin.left + @margin.right)
      .attr("height", @height + @margin.top + @margin.bottom)
    .append("g")
      .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")

    x.domain(d3.extent(month_data, (d) => return d.date ))
    y.domain([0, d3.max(month_data, (d) => return d.count )])

    svg.append("path")
    .attr("class", "line")
    .attr("d", valueline(month_data))

    svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + (@height+1) + ")")
    .call(xAxis)

    svg.append("g")
    .attr("class", "y axis")
    .call(yAxis)
    .append("text")
      .attr("class", "y-label")
      .attr("transform", "rotate(-90)")
      .attr("y",-35)
      .attr("x", -@height/2)
      .style("text-anchor", "middle")
      .text("Test Runs Per Day")
