---
---
window.slice_type = "pie"
slider_val = null
svg = null
chart_area = null
max_pie = null
all_clustered_data = {}
x0 = {}
x1 = {}
y = {}

treemap_props =
  width: null
  height: null

color = d3.scale.category20c() #dt -- not using default scale anymore (might remove)
uhero_color5 = d3.scale.ordinal().range(["#0e5a70", "#1e748d", "#368399", "#579fb3", "#88c2d3"]) #can define domain later?? D:
uhero_color10 = d3.scale.ordinal().range(["#03627F","#1C718B","#358198","#4E91A5","#67A0B2","#81B0BF","#9AC0CB","#B3CFD8","#CCDFE5","#E5EFF2"])
#clustered_color = d3.scale.ordinal().range(["#3182bd", "#6baed6", "#9ecae1"])
clustered_color = uhero_color5
clustered_color3 = d3.scale.ordinal().range(["#0e5a70", "#4E91A5", "#9AC0CB"])

window.treemap_layout = d3.layout.treemap()
  .size([300, 200])
  .sticky(true)
  .value((d) -> d[freq].data[slider_val])

pie_layout = d3.layout.pie()
  .value((d) -> d[freq].data[slider_val])

pie_arc = d3.svg.arc()
  .outerRadius(100)
  .innerRadius(0)

all_dates = ->
  d3.select("#time_slice_slider_div").datum()
    
dates_extent = (extent) ->
  all_dates().slice(extent[0], extent[1]+1)

selected_date = ->
  all_dates()[slider_val]

set_date_shown = ->
  slider_selection = d3.select("#slice_slider_selection").text(selected_date())
  if window.slice_type is 'clustered'
    slider_selection.style("visibility", "hidden")
  else
    slider_selection.style("visibility", "visible")

    
window.redraw_slice = (event, ui) ->
  #console.log "redraw_slice called"
  slider_val = +$("#time_slice_slider_div").val()
  set_date_shown()

  if window.pied is true
    #console.log 'window.pied is true'
    if window.slice_type is "pie"
      #console.log 'window.slice_type is pie'
      pie_slices = chart_area.selectAll("path")
      pie_data = pie_slices.data().map((d) -> d.data)
      pie_slices
        .data(pie_layout(pie_data), (d) -> d.data.display_name)
        .attr("d", pie_arc)

      chart_area.select("text.in_pie_label").remove()

      sorted_array = pie_slices.data().sort((a,b) -> a.value - b.value)
      max_pie = sorted_array.pop()

      chart_area.selectAll("text")
        .data([max_pie])
        .enter()
        .append("text")
        .attr("class","in_pie_label")
        .attr("text-anchor", "middle")
        .attr("transform", (d) -> "translate( #{pie_arc.centroid(d)} )" )
        .append("tspan")
        .attr("class", "pie_slice_name")
        .attr("dy", 20)
        .text((d) -> d.data.display_name)
        .append("tspan")
        .attr("class", "pie_slice_value")
        .attr("dy", 20)
        .attr("x", 0)
        .text((d) -> d.value.toFixed(1)) # keep one decimal place
    else
      #console.log 'window.slice_type isnt pie'
      if window.slice_type is 'treemap'
        #console.log 'window.slice_type is treemap'
        window.node.data(treemap_layout.nodes).call treemap_position
      else
        #console.log 'window.slice_type isnt treemap'
        window.update_clustered_chart slider_val



get_data_index_extent = (data) ->
  start_i = data.findIndex((d) -> d != null)
  end_i = data.length - 1 - data.slice().reverse().findIndex((d) -> d != null)
  [start_i,end_i]
  
get_common_dates = (series_data) ->
  #console.log series_data #dt uncomment
  arr = series_data.map((series) -> get_data_index_extent series[freq].data)
  [d3.max(arr.map((d)-> d[0])), d3.min(arr.map((d)-> d[1]))]
  
mouseover_pie = (d,i) ->
  slice = d3.select(this)
  #slice.attr("fill-opacity", ".3")
  slice.attr("fill", "#ecffc7") # $neon_green

  chart_area.append("text")
    .attr("class","pie_label")
    .attr("text-anchor", "middle")
    .attr("transform", "translate( #{pie_arc.centroid(d)} )" )
    .append("tspan")
    .attr("class", "pie_slice_name")
    .attr("dy", 20)
    .text(d.data.display_name)
    .append("tspan")
    .attr("class", "pie_slice_value")
    .attr("dy", 20)
    .attr("x", 0)
    .text(d.value.toFixed(1)) # keep one decimal place
    
  chart_area.select("text.in_pie_label").remove()

mouseout_pie = (d) ->
  slice = d3.select(this)
  slice.attr("fill-opacity", "1")
    .attr("fill", (d) -> uhero_color5(d.data.display_name))

  chart_area.select("text.pie_label").remove()
  chart_area.selectAll("text")
    .data([d])
    .enter()
    .append("text")
    .attr("class","in_pie_label")
    .attr("text-anchor", "middle")
    .attr("transform", (d) -> "translate( #{pie_arc.centroid(d)} )" )
    .append("tspan")
    .attr("class", "pie_slice_name")
    .attr("dy", 20)
    .text(d.data.display_name)
    .append("tspan")
    .attr("class", "pie_slice_value")
    .attr("dy", 20)
    .attr("x", 0)
    .text(d.value.toFixed(1)) # keep one decimal place
      
set_slider_dates = (extent) ->
  slider_val = extent[1]
  # no need to change the dates, slider indices are still relative
  # to full date / data arrays
  # this causes problems when sharing the slider
  $("#time_slice_slider_div").noUiSlider({ range: {min: extent[0], max: extent[1]} }, true)
  set_date_shown()

window.pie_these_series = (series_data, cluster = false) ->
  if cluster
    window.slice_type = "clustered"
  else
    if series_data[0].display_name is "Construction & Mining"
      window.slice_type = "treemap"
    else
      window.slice_type = "pie"

  data_extent = get_common_dates(series_data)
  set_slider_dates(data_extent)
  chart_area.selectAll("path").remove()

  if cluster
    window.cluster_these_series(series_data)
  else
    sorted_array = pie_layout(series_data).sort((a,b) -> a.value - b.value)
    if window.slice_type is "pie"
      max_pie = sorted_array.pop()
      # pie graphic
      chart_area.selectAll("path")
        .data(pie_layout(series_data), (d) -> d.data.display_name)
        .enter()
        .append("path")
        .attr("d", pie_arc)
        .attr("fill", (d) -> clustered_color(d.data.display_name))
        .attr("stroke", "white")
        .attr("stroke-width", 2)
        .on("mouseover", mouseover_pie)
        .on("mouseout", mouseout_pie)
      # pie labels
      chart_area.selectAll("text")
        .data([max_pie])
        .enter()
        .append("text")
        .attr("class","in_pie_label")
        .attr("text-anchor", "middle")
        .attr("transform", (d) -> "translate( #{pie_arc.centroid(d)} )" )
        .append("tspan")
        .attr("class", "pie_slice_name")
        .attr("dy", 20)
        .text((d) -> d.data.display_name)
        .append("tspan")
        .attr("class", "pie_slice_value")
        .attr("dy", 20)
        .attr("x", 0)
        .text((d) -> d.value.toFixed(1)) # keep one decimal place
    else
      chart_area.attr("transform", "translate(0,50)")
      # treemap
      window.node = chart_area.datum({children: series_data}).selectAll("rect")
        .data(treemap_layout.nodes)
        .enter().append("rect")
        .call treemap_position
        .attr("fill", (d) ->
          switch d.depth
            when 2 then uhero_color10 d.parent.display_name
            when 3 then uhero_color10 d.parent.parent.display_name
            else uhero_color10 d.display_name
        )
        .on "mousemove", treemap_mousemove
        .on "mouseout", treemap_mouseout
      # add subtitle
      pie_notes = svg.append("text")
        .attr("id", "pie_notes")
        .attr("text-anchor", "start")
        .attr("x", 0)
        .attr("y", svg.attr("height") - 40)
      pie_notes.append("tspan").attr("dy", 0).text("The area of each box represents the number of jobs in each category.")
      pie_notes.append("tspan").attr("dy", 10).text("Colors indicate top-level categories (e.g., Total Government Jobs).").attr("x", 0)
    d3.select("#pie_heading").text($(".series.parent").first().prev().text().trim().replace("Total", "") + " (" + d3.selectAll($(".series.parent").first().next()).datum().units + ")")

treemap_mousemove = (d) ->
  xPosition = d3.event.pageX + 5
  yPosition = d3.event.pageY + 5

  d3.select "#treemap_tooltip"
    .style "left", xPosition + "px"
    .style "top", yPosition + "px"
  d3.select "#treemap_tooltip #treemap_tooltip_heading"
    .text () ->
      switch d.depth
        when 2 then "#{d.display_name} (#{d.parent.display_name})"
        when 3 then "#{d.display_name} (#{d.parent.display_name} - #{d.parent.parent.display_name})"
        else d.display_name
  d3.select("#treemap_tooltip #treemap_tooltip_percentage")
    .text () ->
      "YOY: " + d[freq].yoy[slider_val].toFixed(1) + "%"
  d3.select("#treemap_tooltip #treemap_tooltip_value")
    .text(d.value.toFixed(3))
  d3.select("#treemap_tooltip").classed "hidden", false

treemap_mouseout = (d) ->
  d3.select("#treemap_tooltip").classed("hidden", true)

treemap_position = () ->
  this.attr
    x: (d) -> d.x + "px"
    y: (d) -> d.y + "px"
    width: (d) -> d.dx + "px"
    height: (d) -> d.dy + "px"

# this is the main function that instantiates the time-slice chart
window.visitor_pie_chart = (container) ->
  slider_val = all_dates().length-1
  svg = set_up_svg(container)

  center_x = svg.attr("width") / 2
  center_y = svg.attr("height") / 2

  treemap_props.width = svg.attr("width")
  treemap_props.height = svg.attr("height")

  svg.append("text")
    .attr("id", "pie_heading") #dt may want to change this to "pie_header" for consistency
    .attr("text-anchor", "middle")
    .attr("x", center_x)
    .attr("y", 20)

  chart_area = svg.append("g")
    .attr("id", "pie_chart_area")
    .attr("transform", "translate(#{center_x},#{center_y})")

  svg.append("text")
    .attr("id", "slice_slider_selection")
    .attr("text-anchor", "middle")
    .attr("x", center_x)
    .attr("y", svg.attr("height")-10)
    .text("2013")
    
# stuff for clustered bar charts
x = d3.scale.linear().clamp(true).range([ 0, 15 ])
y = d3.scale.linear()
x0 = d3.scale.ordinal()

selected_dates = ->
  all_dates()[(slider_val-4)..slider_val]

#selected_data = (d) ->
  #yoy = d[freq].yoy[(slider_val-4)..slider_val]
  #d[freq].data[(slider_val-4)..slider_val].map (d, i) ->
    #{data: d, yoy: yoy[i]}

# takes series_data as its argument
selected_data = (d) ->
  [(slider_val - 4)..slider_val].map (index) ->
    period =
      period: all_dates()[index]
    period.series = d.map (series) ->
      {name: series.display_name, value: +series[freq].yoy[index]}
    period

window.cluster_these_series = (series_data) ->
  all_clustered_data = series_data
  #x0.rangeRoundBands([0, svg.attr("width")], .1)
  #console.log series_data
  #console.log 'selected_dates'
  #console.log selected_dates()
  #console.log(selected_data series for series in series_data)
  #console.log JSON.stringify(selected_data series_data)

  # setup
  #margin = {top: 20, right: 20, bottom: 30, left: 40}
  #width = 396 - margin.left - margin.right
  #height = 189 - margin.top - margin.bottom
  width = svg.attr('width')
  height = (svg.attr('height') - 30) #to match axis of opposite graph
  x0 = d3.scale.ordinal().rangeRoundBands([0, width], 0.2)
  x1 = d3.scale.ordinal()
  #console.log("height" + height)
  y = d3.scale.linear().range([height, 0])

  xAxis = d3.svg.axis().scale(x0).orient("bottom")
  yAxis = d3.svg.axis().scale(y).orient("right").tickFormat(d3.format(".2s"))
  #svg = d3.select("svg")
    #.attr("width", width + margin.left + margin.right)
    #.attr("height", height + margin.top + margin.bottom)
    #.append("g")
    #.attr("transform", "translate(" + margin.left + "," + margin.top + ")")

  # remap data
  data = selected_data series_data
  seriesNames = ["Real Personal Income", "Total Visitor Days", "Total Non-farm Payrolls"] #have to match series names
  x0.domain(data.map((d) -> d.period)) #years (x-axis)
  x1.domain(seriesNames).rangeRoundBands([0, x0.rangeBand()])
  #y.domain([d3.min(data, function(d) { return d3.min(d.series, function(d) { return d.value; }); }),
  #          d3.max(data, function(d) { return d3.max(d.series, function(d) { return d.value; }); })]);
  y.domain([-20,20]) #y-axis scale

  #svg = set_up_svg(container)
  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + (height+30) + ")")
    .call(xAxis)

  svg.append("text") #appended title separately to move it above graph
    .text("Growth Rate")
    .attr("y", 20)
    #.attr("dy", ".71em")
    .attr("x",(width/2))
    .attr("id","cluster_heading")
    .style("text-anchor", "middle") #text-align

  svg.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(" + width + ", 30)")
    .call(yAxis)
    ###
    .append("text")
    #.attr("transform", "translate(-10, 0)")
    #.attr("transform", "rotate(-90), translate(0, 30)")
    .attr("y", 20)
    #.attr("dy", ".71em")
    .attr("x",-(width/2))
    .attr("id","cluster_heading")
    .style("text-anchor", "middle") #text-align
    .text("Growth Rate")
    ###

  period = svg.selectAll(".period")
    .data(data)
    .enter().append("g")
    .attr("class", "g")
    .attr("transform", (d) -> "translate(" + x0(d.period) + ",30)")

  period.selectAll("rect")
    .data((d) -> d.series)
    .enter().append("rect")
    .classed("series_bars", true)
    .attr("width", x1.rangeBand())
    .attr("x", (d) -> x1(d.name))
    
    .attr("y", (d) -> y(d3.max([0, d3.min([20, d.value])])))
    .attr("height", (d) -> y(0)-y(d3.min([20, Math.abs(d.value)])))
    .style("fill", (d) -> clustered_color3(d.name))

  legend = svg.selectAll(".legend")
    .data(seriesNames.slice())
    .enter().append("g")
    .attr("class", "legend")
    .attr("transform", (d, i) -> "translate(-10," + i * 20 + ")")

  legend.append("rect")
    .attr("x", width - 18)
    .attr("y", 39)
    .attr("width", 18)
    .attr("height", 18)
    .style("fill", clustered_color3)

  legend.append("text")
    .attr("x", width - 24)
    .attr("y", 47) #dt
    .attr("dy", ".35em")
    .classed("clustered_bar_legend", true)
    .style("text-anchor", "end")
    .text((d) -> d)

  #cluster_series = chart_area.selectAll(".cluster_series")
    #.data(data)
    #.enter().append("g")
    #.attr("class", "g")
    #.attr("transform", (d) -> "translate(" + x0(d.udaman_name) + ",0)")

  #cluster_series.selectAll("rect")
    #.data((d) -> selected_data(d) )
    #.enter().append("rect")
    #.attr("width", 1)
    #.attr("x", (d) ->  x1(d.year))
    #.attr("y", (d) -> y(d.yoy))
    #.attr("height", (d) -> height - y(d.yoy))

window.update_clustered_chart = (slider_val) ->
  #console.log "update_clustered_chart called"
  seriesNames = ["Real Personal Income", "Total Visitor Days", "Total Non-farm Payrolls"]
  #console.log selected_data
  data = selected_data all_clustered_data
  
  # update period labels
  width = svg.attr('width')
  height = svg.attr('height')
  x0 = d3.scale.ordinal().rangeRoundBands([0, width], 0.1)
  x0.domain(data.map((d) -> d.period))
  xAxis = d3.svg.axis().scale(x0).orient("bottom")
  svg.selectAll(".x.axis")
    .attr("transform", "translate(0," + (height) + ")") #don't adjust height here
    .call(xAxis)

  # remove old bars
  svg.selectAll("rect.series_bars").remove()

  # update bars
  period = svg.selectAll(".period")
    .data(data)
  period.enter().append("g")
    #.attr("class", "g")
    .attr("transform", (d) -> "translate(" + x0(d.period) + ",30)")

  series = period.selectAll("rect")
    .data((d) -> d.series)
  series.remove()
  series.enter().append("rect")
    .classed("series_bars", true)
    .attr("width", x1.rangeBand())
    .attr("x", (d) -> x1(d.name))
    .attr("y", (d) -> y(d3.max([0, d3.min([20, d.value])])))
    .attr("height", (d) -> y(0)-y(d3.min([20, Math.abs(d.value)])))
    .style("fill", (d) -> clustered_color3(d.name))
  series.exit().remove()

  # clear legend and recreate it
  svg.selectAll(".legend").remove()
  legend = svg.selectAll(".legend")
    .data(seriesNames.slice())
    .enter().append("g")
    .attr("class", "legend")
    .attr("transform", (d, i) -> "translate(-10," + i * 20 + ")")

  legend.append("rect")
    .attr("x", width - 18)
    .attr("y", 39)
    .attr("width", 18)
    .attr("height", 18)
    .style("fill", clustered_color3)

  legend.append("text")
    .attr("x", width - 24)
    .attr("y", 47)
    .attr("dy", ".35em")
    .classed("clustered_bar_legend", true)
    .style("text-anchor", "end")
    .text((d) -> d)
