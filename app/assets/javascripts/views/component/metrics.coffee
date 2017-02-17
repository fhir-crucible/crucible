$(document).ready( ->
  new Crucible.ServerScroller()
)

class Crucible.CalendarChart
	width: 960
	height:136
	cellSize: 17

	format: d3.time.format("%Y-%m-%d")

	color: d3.scale.quantize()
		.domain(d3.extent(test_data, function(d) { return Math.log(d.count); }))
    	.range(d3.range(9).map(function(d) { return "q" + d + "-9"; }));

    constructor: ->
    	@element = $('.calendar-chart')
    	@loadData()

    loadData: =>
    	$.getJSON('/calendar_chart_data')
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
    	if d.getFullYear() == startDate.getFullYear()
    		return d3.time.weekOfYear(d) - d3.time.weekOfYear(startDate)
    	else
    		weekDay = d.getDay()
    		days = d3.time.dayOfYear( d ) + 1 + d3.time.dayOfYear(new Date( endDate.getFullYear(), 0, 0)) - d3.time.dayOfYear(startDate)
    		week = Math.floor((days + startDate.getDay() ) / 7)
    		return week

    monthPath: (t0) =>
    	t1 = new Date(t0.getFullYear(), t0.getMonth() + 1, 0),
		d0 = t0.getDay(), w0 = getWeek(t0),
	    d1 = t1.getDay(), w1 = getWeek(t1);
		return "M" + (w0 + 1) * cellSize + "," + d0 * @['cellSize']
			+ "H" + w0 * @['cellSize'] + "V" + 7 * @['cellSize']
			+ "H" + w1 * @['cellSize'] + "V" + (d1 + 1) * @['cellSize']
			+ "H" + (w1 + 1) * @['cellSize'] + "V" + 0
			+ "H" + (w0 + 1) * @['cellSize'] + "Z"

    renderChart: (data) =>
    	now = new Date()
    	startDate = new Date( now.getFullYear() - 1, now.getMonth()+1, 1)
    	endDate = new Date( now.getFullYear(), now.getMonth() + 1, 1)

    	svg = d3.select(@element[0]).append("svg")
    		.data([now])
    		.enter().append("svg")
    		.attr("width", @['width'])
    		.attr("height", @['height'])
    		.attr("class", "YlOrBr")
    			.append("g")
    		.append("g")
    			.attr("transform", "translate(" + ((@['width'] - @['cellSize'] *53) / 2) + "," + (@['height'] - @['cellSize'] * 7 - 1) ")")

    	svg.append("text")
    		,attr("transform", "translate(-30," + @['cellSize'] * 3.5 + ")rotate(-90)")
    		.style("text-anchor", "middle")
    		.text("Last 12 Months")

    	rect = svg.selectAll(".day")
    		.data( (d) => return d3.time.days(startDate, endDate) )
    		.enter().append("rect")
    			.attr("class", "day")
    			.attr("width" @['cellSize'])
    			.attr("height", @['cellSize'])
    			.attr("x", (d) => return @getWeek(d) * @['cellSize'])
    			.attr("y", (d) => return d.getday() * @['cellSize'])
    			.datum(format)

    	rect.append("title")
    		.text( (d) => return d )

    	svg.selectAll(".month")
    		.data( (d) => return d3.time.months(startDate, endDate) )
    		.enter().append("path")
    			.attr("class", "month")
    			.attr("d", @monthPath)

    	dates = d3.time.days(startDate, endDate)
    	data = {}
		dates.forEach( (date) =>
  			data[@format(date)] = 0;
		)

		test_data.forEach( (d) =>
		  data[format(d.date)] = Math.log(d.count);
		)

		rect.filter( (d) => return d in data )
			.attr("class", (d) => return "day " + color(data[d]) )
			.select("title")
			.text( (d) => return d + ": " + data[d] )

		var weekDays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
        month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

	    var titlesDays = svg.selectAll('.titles-day')
	        .data(weekDays)
	        .enter().append('g')
	        .attr('class', 'titles-day')
	        .attr('transform', function (d, i) {
	            return 'translate(-5,' + ( 15 + (height-15)/ 7 * i) + ')';
	        });
	    
	    titlesDays.append('text')
	        .attr('class', function (d,i) { return weekDays[i]; })
	        .style('text-anchor', 'end')
	        .attr('dy', '-.25em')
	        .text(function (d, i) { return weekDays[i]; }); 

	    var titlesMonth = svg.selectAll('.titles-month')
	            .data(month)
	        .enter().append('g')
	            .attr('class', 'titles-month')
	            .attr('transform', function (d, i) { 
	                return 'translate(' + (( (  ( (i - endDate.getMonth() + 12) % 12) + 1) * (cellSize * 53 /12) )-30) + ',-5)'; 
	            });

	    titlesMonth.append('text')
	        .attr('class', function (d,i) { return month[i]; })
	        .style('text-anchor', 'end')
	        .text(function (d,i) { return month[i]; });
