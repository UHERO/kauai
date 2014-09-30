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

# ------------------------------------


all_dates = ->
  d3.select("#line_chart_slider_div").datum()
    
dates_extent = (extent) ->
  all_dates().slice(extent[0], extent[1]+1)

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

combine_extent = (ex1, ex2) ->
  [ d3.min([ex1[0],ex2[0]]), d3.max([ex1[1],ex2[1]]) ]


toggle_axis_button = (series, axis) ->
  button = d3.select("#s_row_#{series_to_class(series)} .#{axis}_toggle")
  if button.classed("off")
    button.text("-").attr("class", "#{axis}_toggle on")
  else
    button.text("+").attr("class", "#{axis}_toggle off")

trim_d = (d, extent) ->
  d.trimmed_data = d.data.slice(extent[0], extent[1]+1)

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
  
redraw_line_chart = (extent, duration = 0) ->
  update_x_domain(extent)

  l_paths = d3.selectAll("g#chart_area path.s_left")
    .attr("d", (d) -> regenerate_path(d, extent, "left") )

  r_paths = d3.selectAll("g#chart_area path.s_right")
    .attr("d", (d) -> regenerate_path(d, extent, "right") )
    
window.trim_time_series = (event, ui) ->
  slider_extent = ui.values
  redraw_line_chart(slider_extent)

window.add_to_line_chart = (d, axis) ->
  duration = 500
  trim_d d[freq], slider_extent
  domain = chart_extent(d[freq].data)  
  path = d3.select("g#chart_area #path_#{series_to_class(d.udaman_name)}")

  update_y_domain_with_new(axis, domain, duration)
  
  path.classed("#{y[axis].class}", true)
    .attr("d", (d) -> dummy_path(d[freq].trimmed_data))
    
  d3.selectAll("g#chart_area path.#{y[axis].class}") 
    .transition()
    .duration(duration)
    .attr("d", (d) -> y[axis].path(d[freq].trimmed_data))
  
  toggle_axis_button(d.udaman_name, axis)


window.remove_from_line_chart = (d, axis) ->
  duration = 500
  chart_area = d3.select("g#chart_area")  
  path = d3.select("g#chart_area #path_#{series_to_class(d.udaman_name)}")

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
    .attr("id", (d) -> "path_#{series_to_class(d.udaman_name)}")
    .attr("class", (d) -> "#{series_to_class(d.udaman_name)} line_chart_path")
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