# Get the data

rawData = <%= raw @tests_json %>
test_data = []
month_data = []
rawData.forEach(function(d) {
  test_data.push( {
    date: new Date(d._id.year, 0, d._id.day),
    count: d.count
  })

  if( (new Date().getTime() - new Date(d._id.year, 0, d._id.day).getTime())/(1000*60*60*24.0) < 60) {
    month_data.push( {
      date: new Date(d._id.year, 0, d._id.day),
      count: d.count
    })
  }
});

month_data.sort(function(a,b) {
  a = a.date;
  b = b.date;
  return a<b ? -1 : a>b ? 1 : 0;
});

total = 0
for( i = 0; i < month_data.length; i++) {
  total += month_data[i].count
  month_data[i].count = total
}

test_frequency = <%= raw @test_frequency %>;

now = new Date();
startDate = new Date( now.getFullYear() - 1, now.getMonth()+1, 1)
endDate = new Date( now.getFullYear(), now.getMonth() + 1, 1)

width = 960,
    height = 136,
    cellSize = 17; // cell size

percent = d3.format(".1%"),
    format = d3.time.format("%Y-%m-%d");

color = d3.scale.quantize()
    .domain(d3.extent(test_data, function(d) { return Math.log(d.count); }))
    .range(d3.range(9).map(function(d) { return "q" + d + "-9"; }));

svg = d3.select("#calendarGraph").selectAll("svg")
    .data([ now ])
  .enter().append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("class", "YlOrBr")
  .append("g")
    .attr("transform", "translate(" + ((width - cellSize * 53) / 2) + "," + (height - cellSize * 7 - 1) + ")");

svg.append("text")
    .attr("transform", "translate(-30," + cellSize * 3.5 + ")rotate(-90)")
    .style("text-anchor", "middle")
    .text("Last 12 Months");

rect = svg.selectAll(".day")
    .data(function(d) { return d3.time.days(startDate, endDate); })
  .enter().append("rect")
    .attr("class", "day")
    .attr("width", cellSize)
    .attr("height", cellSize)
    .attr("x", function(d) {
       return getWeek(d) * cellSize; })
    .attr("y", function(d) { return d.getDay() * cellSize; })
    .datum(format);

rect.append("title")
    .text(function(d) { return d; });

svg.selectAll(".month")
    .data(function(d) { return d3.time.months(startDate, endDate); })
  .enter().append("path")
    .attr("class", "month")
    .attr("d", monthPath);

dates = d3.time.days(startDate, endDate);
data = {};
dates.forEach(function(date) {
  data[format(date)] = 0;
});

test_data.forEach( function(d) {
  data[format(d.date)] = Math.log(d.count);
});

rect.filter(function(d) { return d in data; })
      .attr("class", function(d) { return "day " + color(data[d]); })
    .select("title")
      .text(function(d) { return d + ": " + percent(data[d]); });

function getWeek(d) {
  if( d.getFullYear() == startDate.getFullYear() ) {
    return d3.time.weekOfYear(d) - d3.time.weekOfYear(startDate);
  } else {
    weekDay = d.getDay();
    days = d3.time.dayOfYear( d ) + 1 + d3.time.dayOfYear(new Date( endDate.getFullYear(), 0, 0)) - d3.time.dayOfYear(startDate);
    week = Math.floor((days + startDate.getDay() ) / 7);
    return week;
  }
}

function monthPath(t0) {
  t1 = new Date(t0.getFullYear(), t0.getMonth() + 1, 0),
      d0 = t0.getDay(), w0 = getWeek(t0),
      d1 = t1.getDay(), w1 = getWeek(t1);
  return "M" + (w0 + 1) * cellSize + "," + d0 * cellSize
      + "H" + w0 * cellSize + "V" + 7 * cellSize
      + "H" + w1 * cellSize + "V" + (d1 + 1) * cellSize
      + "H" + (w1 + 1) * cellSize + "V" + 0
      + "H" + (w0 + 1) * cellSize + "Z";
}

// day and week titles
function chartTitles() {

    weekDays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
        month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    titlesDays = svg.selectAll('.titles-day')
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

    titlesMonth = svg.selectAll('.titles-month')
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

}

chartTitles();

</script>

<style> /* set the CSS */

#lineChart { font: 12px Arial;}

#lineChart path { 
    stroke: rgb(0,104,55);
    stroke-width: 2;
    fill: none;
}

#lineChart .axis path,
#lineChart .axis line {
    fill: none;
    stroke: grey;
    stroke-width: 1;
    shape-rendering: crispEdges;
}

</style>

<script>

// Set the dimensions of the canvas / graph
margin = {top: 30, right: 20, bottom: 30, left: 50},
    width = 538 - margin.left - margin.right,
    height = 300 - margin.top - margin.bottom;

// Parse the date / time
parseDate = d3.time.format("%d-%b-%y").parse;

// Set the ranges
x = d3.time.scale().range([0, width]);
y = d3.scale.linear().range([height, 0]);

// Define the axes
xAxis = d3.svg.axis().scale(x)
    .orient("bottom").ticks(5);

yAxis = d3.svg.axis().scale(y)
    .orient("left").ticks(5);

// Define the line
valueline = d3.svg.line()
    .x(function(d) { return x(d.date); })
    .y(function(d) { return y(d.count); });
    
// Adds the svg canvas
svg = d3.select("#lineChart")
    .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
    .append("g")
        .attr("transform", 
              "translate(" + margin.left + "," + margin.top + ")");


// Scale the range of the data
x.domain(d3.extent(month_data, function(d) { return d.date; }));
y.domain([0, d3.max(month_data, function(d) { return d.count; })]);

// Add the valueline path.
svg.append("path")
    .attr("class", "line")
    .attr("d", valueline(month_data));

// Add the X Axis
svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);

// Add the Y Axis
svg.append("g")
    .attr("class", "y axis")
    .call(yAxis);

</script>

<style>

  #barChart .axis {
    font: 10px sans-serif;
  }

  #barChart .axis path,
  #barChart .axis line {
    fill: none;
    stroke: #000;
    shape-rendering: crispEdges;
  }

</style>

<script>

margin = {top: 20, right: 20, bottom: 70, left: 40},
    width = 538 - margin.left - margin.right,
    height = 300 - margin.top - margin.bottom;


x = d3.scale.ordinal().rangeRoundBands([0, width], .05);

y = d3.scale.linear().range([height, 0]);

xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

yAxis = d3.svg.axis()
    .scale(y)
    .orient("left")
    .ticks(10);

svg = d3.select("#barChart").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", 
          "translate(" + margin.left + "," + margin.top + ")");

x.domain(test_frequency.map(function(d) { return d._id; }));
y.domain([0, d3.max(test_frequency, function(d) { return d.count; })]);

svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)
  .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", "-.55em")
    .attr("transform", "rotate(-45)" );

svg.append("g")
    .attr("class", "y axis")
    .call(yAxis)
  .append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", 6)
    .attr("dy", ".71em")
    .style("text-anchor", "end")
    .text("Tests");

svg.selectAll("bar")
    .data(test_frequency)
  .enter().append("rect")
    .style("fill", function(d,i) {
      if(i%2 == 0) {return "rgb(254,153,41)" }
      else {return "rgb(153,52,4)"}
    })
    .attr("x", function(d) { return x(d._id); })
    .attr("width", x.rangeBand())
    .attr("y", function(d) { return y(d.count); })
    .attr("height", function(d) { return height - y(d.count); });

</script>