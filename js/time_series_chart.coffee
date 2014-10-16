---
---
slider_extent = null

x_from_slider = (d,i) ->
  x(all_dates()[slider_extent[0] + i])
  
#---- Line Chart variables ---------

y_left = d3.scale.linear()
y_right = d3.scale.linear()

x = d3.scale.ordinal()
window.x_scale = x  
y =
  left:
    class:"s_left"
    scale: y_left 
    axis: d3.svg.axis().scale(y_left).orient("left")
    path: d3.svg.line()
            .x(x_from_slider)
            .y((d) -> y_left(d))
            .defined((d) -> d isnt null)
  right:
    class:"s_right"
    scale: y_right
    axis: d3.svg.axis().scale(y_right).orient("right")
    path: d3.svg.line()
            .x(x_from_slider)
            .y((d) -> y_right(d))
            .defined((d) -> d isnt null)
    

time_axis = d3.svg.axis().scale(x).tickFormat((d,i) -> if i is 0 or i is (slider_extent[1] - slider_extent[0]) then d else "")

dummy_path = d3.svg.line()
  .x(x_from_slider)
  .y(-20)
  .defined((d) -> d isnt null)


y_yoy = (d) ->
  if d < 0 then y_right(0) else y_right(d)

y_height = (d)->
  Math.abs(y_right(0)-y_right(d))

# ------------------------------------


all_dates = ->
  #d3.select("#line_chart_slider_div").datum()
  d3.select("#sparkline_slider_div").datum() #dt
    
dates_extent = (extent) ->
  # debugging an issue with the line_chart not updating
  console.log extent
  date_extent = all_dates().slice(parseInt(parseInt(extent[0])), parseInt(extent[1])+1)
  console.log "date_extent -> #{JSON.stringify date_extent}"
  date_extent

slider_dates = ->
  extent = slider_extent
  dates_extent(extent)
  
chart_extent = (array) ->
  full_extent = d3.extent(array)
  range = full_extent[1] - full_extent[0]
  [
    full_extent[0] - range*.1
    full_extent[1] + range*.1
  ]

yoy_chart_extent = (array) ->
  full_extent = d3.extent(array)
  range = full_extent[1] - full_extent[0]
  [
    full_extent[0] - range*.1
    full_extent[1] + range*.1
  ]
  
combine_extent = (ex1, ex2) ->
  [ d3.min([ex1[0],ex2[0]]), d3.max([ex1[1],ex2[1]]) ]


toggle_axis_button = (series, axis) ->
  button = d3.select("#s_row_#{window.series_to_class(series)} .#{axis}_toggle")
  if button.classed("off")
    button.text("-").attr("class", "#{axis}_toggle on")
  else
    button.text("+").attr("class", "#{axis}_toggle off")

s_path = (udaman_name) ->
  d3.select("g#chart_area #path_#{window.series_to_class(udaman_name)}")

trim_d = (d, extent) ->
  d.trimmed_data = d.data.slice(extent[0], extent[1]+1)

trim_yoy = (d, extent) ->
  d.trimmed_yoy = d.yoy.slice(extent[0], extent[1] + 1)
  
update_x_domain = (extent, duration=0) ->
  x.domain(dates_extent(extent))

update_domain = (axis, duration = 500) ->
  data = d3.select("g#chart_area").selectAll(".#{y[axis].class}").data().map((d) -> d[freq].data)

  if data.length == 0
    y[axis].scale.domain([0,1])
  else
    all_data = []
    all_data = all_data.concat(series) for series in data
    y[axis].scale.domain(chart_extent(all_data))

  d3.select("##{axis}_axis")
    .transition()
    .duration(duration)
    .call(y[axis].axis)

update_y_domain_with_new = (axis, domain, duration = 500) ->
  cur_domain = y[axis].scale.domain()
  
  unless d3.select("g#chart_area").selectAll("path."+y[axis].class).empty()
    domain = combine_extent(cur_domain, domain)
  
  y[axis].scale.domain(domain).nice()
  
  d3.select("##{axis}_axis")
    .transition()
    .duration(duration)
    .call(y[axis].axis)


regenerate_path = (d, extent, axis) ->
  trim_d d[freq], extent
  y[axis].path(d[freq].trimmed_data)

show_bars = (d,extent) ->
  duration = 500
  trim_yoy d[freq], extent
  
  bars = d3.select("g#chart_area")
    .selectAll("rect.yoy")
    .data(d[freq].trimmed_yoy)
  
  bars.enter()
    .append("rect")
    .attr("class", "yoy")
    .attr("fill", "gray")
    .attr("fill-opacity", 0.5)
    .attr("y", y_right(0))
    .attr("x", x_from_slider) 
    .attr("height", 0)
    .attr("width", 1)
     
  bars
    .transition()
    .duration(duration)
    .attr("y", y_yoy)
    .attr("height", y_height)
  
regenerate_bars = (d,extent) ->
  trim_yoy d[freq], extent
  
  bars = d3.select("g#chart_area")
    .selectAll("rect.yoy")
    .data(d[freq].trimmed_yoy)
  
  bars.enter()
    .append("rect")
    .attr("class", "yoy")
    .attr("fill", "gray")
    .attr("fill-opacity", 0.5)
    
  bars.exit().remove()
  
  bars
    .attr("x", x_from_slider)
    .attr("y", y_yoy)
    .attr("width", 1)
    .attr("height", y_height)

hide_bars = ->
  duration = 500
  bars = d3.select("g#chart_area")
    .selectAll("rect.yoy")
    .transition()
    .duration(duration)
    .attr("y", y_right(0))
    .attr("height", 0)
  
  # alternatively can hide this axis
  y["right"].scale.domain([0,1])

  d3.select("#right_axis")
    .transition()
    .duration(duration)
    .call(y["right"].axis)

window.redraw_line_and_bar_chart = (extent) ->
  update_x_domain(extent)
  path = d3.select("g#chart_area path.with_bar")
    .attr("d", (d) -> regenerate_path(d, extent, "left") )
  
  regenerate_bars(path.datum(), extent)
  
    
window.redraw_line_chart = (extent, duration = 0) ->
  update_x_domain(extent)

  l_paths = d3.selectAll("g#chart_area path.s_left")
    .attr("d", (d) -> regenerate_path(d, extent, "left") )

  r_paths = d3.selectAll("g#chart_area path.s_right")
    .attr("d", (d) -> regenerate_path(d, extent, "right") )
    
# change this
#window.trim_time_series = (event, ui) ->
  ###
window.trim_time_series = (event) ->
  slider_extent =  $("#line_chart_slider_div").val().map (value) -> +value
  console.log JSON.stringify slider_extent 
  d3.select("h3#date_line_left").text(all_dates()[slider_extent[0]])
  d3.select("h3#date_line_right").text(all_dates()[slider_extent[1]])
  #if d3.select("#line_chart_slider_container a.ui-state-focus").attr("slider") == "left"
    #text = d3.select("#line_chart_slider_container a.ui-state-focus").style("left").split("px")
    ##console.log(text)
    #d3.select("h3#date_line_left").style("left", (parseInt(text[0]) + 480) + "px")
  
  #if d3.select("#line_chart_slider_container a.ui-state-focus").attr("slider") == "right"
    #text = d3.select("#line_chart_slider_container a.ui-state-focus").style("left").split("px")
    #d3.select("h3#date_line_right").style("left", (parseInt(text[0]) + 480) + "px")
    
  switch window.mode
    when "multi_line" then redraw_line_chart(slider_extent)
    when "line_bar" then redraw_line_and_bar_chart(slider_extent)
    else redraw_line_chart(slider_extent)
##
###
window.line_and_bar_to_multi_line = (d) ->
  hide_bars()

  d3.select("g#chart_area path.with_bar")    
    .classed("with_bar",false)
    .classed("s_left", true)
  
  add_to_line_chart(d,"left")  
  window.mode = "multi_line"
  
window.multi_line_to_line_and_bar = (d) ->
  duration = 500
  clear_from_line_chart(d)
  keep_path = d3.select("g#chart_area path.s_left, g#chart_area path.s_right")
    .classed("with_bar", true)
  kp_d = keep_path.datum()
  yoy_domain = yoy_chart_extent(kp_d[freq].yoy)
  update_y_domain_with_new("right", yoy_domain, duration)
  show_bars(kp_d, slider_extent)
  window.mode = "line_bar"
    
window.clear_from_line_chart = (d) ->
  path = s_path d.udaman_name
  axis = if path.classed("s_left") then "left" else "right"
  remove_from_line_chart(d,axis)
  
window.clear_line_and_bar_chart = (d) ->
  hide_bars()
  remove_from_line_chart(d,"left")
  
window.display_line_and_bar_chart = (d) ->
  highlight_series_row(d)
  duration = 500
  trim_d d[freq], slider_extent
  domain = chart_extent(d[freq].data) 
  yoy_domain = yoy_chart_extent(d[freq].yoy)
   
  path = d3.select("g#chart_area #path_#{window.series_to_class(d.udaman_name)}")
  
  update_y_domain_with_new("left", domain, duration)
  update_y_domain_with_new("right", yoy_domain, duration)
  
  path
    .classed("with_bar", true)
    .attr("d", (d) -> dummy_path(d[freq].trimmed_data))

  path
    .transition()
    .duration(duration)
    .attr("d", (d) -> y["left"].path(d[freq].trimmed_data))
    
  show_bars(d, slider_extent)
    
window.add_to_line_chart = (d, axis) ->
  duration = 500
  trim_d d[freq], slider_extent
  domain = chart_extent(d[freq].data)  
  path = d3.select("g#chart_area #path_#{window.series_to_class(d.udaman_name)}")

  update_y_domain_with_new(axis, domain, duration)
  
  path
    .classed("#{y[axis].class}", true)
    .attr("d", (d) -> dummy_path(d[freq].trimmed_data))
    
  d3.selectAll("g#chart_area path.#{y[axis].class}") 
    .transition()
    .duration(duration)
    .attr("d", (d) -> y[axis].path(d[freq].trimmed_data))
  
  toggle_axis_button(d.udaman_name, axis)


window.remove_from_line_chart = (d, axis) ->
  duration = 500
  chart_area = d3.select("g#chart_area")  
  path = d3.select("g#chart_area #path_#{window.series_to_class(d.udaman_name)}")

  path.classed("s_#{axis}", false)
  path.transition()
    .duration(500)
    .attr("d", (d) -> dummy_path(d[freq].trimmed_data))
    
  update_domain(axis, duration)

  chart_area.selectAll("path.#{y[axis].class}")
    .transition()
    .duration(duration)
    .attr("d", (d) -> y[axis].path(d[freq].trimmed_data))

  toggle_axis_button(d.udaman_name, axis)


window.set_up_line_chart_paths = (data) ->
  d3.select("g#chart_area")
    .selectAll("path.line_chart_path")
    .data(data)
    .enter()
    .append("path")
    .attr("id", (d) -> "path_#{window.series_to_class(d.udaman_name)}")
    .attr("class", (d) -> "#{window.series_to_class(d.udaman_name)} line_chart_path")
    .attr("stroke", "#777")
    
window.line_chart = (container) ->
  svg = set_up_svg(container)
  margin = 
    top: 10
    bottom: 20
    left: 50
    right: 50

  chart_area_width = svg.attr("width") - margin.left-margin.right
  chart_area_height = svg.attr("height") - margin.top - margin.bottom

  slider_extent = [0, all_dates().length-1]
  update_x_domain(slider_extent)
  x.rangePoints([0, chart_area_width])
  y.left.scale.range([chart_area_height,0])
  y.right.scale.range([chart_area_height,0])
  # y_yoy.range([chart_area_height,0])
  
  svg.append("g")
    .attr("id", "left_axis")
    .attr("transform", "translate(#{margin.left},#{margin.top})")
    .call(y.left.axis)
  
  svg.append("g")
    .attr("id", "right_axis")
    .attr("transform", "translate(#{margin.left+chart_area_width},#{margin.top})")
    .call(y.right.axis)

  chart_area = svg.append("g")
    .attr("id", "chart_area")
    .attr("transform", "translate(#{margin.left},#{margin.top})")
