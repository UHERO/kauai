---
---
start_date = 2004
end_date = 2013

#---- Line Chart variables ---------

y_left = d3.scale.linear()
y_right = d3.scale.linear()
x = d3.scale.ordinal().domain(num for num in [start_date..end_date])
  
y =
  left:
    class:"s_left"
    scale: y_left 
    axis: d3.svg.axis().scale(y_left).orient("left")
    path: d3.svg.line()
            .x((d) -> x(+d.period))
            .y((d) -> y_left(d.val))
  right:
    class:"s_right"
    scale: y_right
    axis: d3.svg.axis().scale(y_right).orient("right")
    path: d3.svg.line()
            .x((d) -> x(+d.period))
            .y((d) -> y_right(d.val))
    

time_axis = d3.svg.axis().scale(x)

dummy_path = d3.svg.line()
  .x((d,i) -> x(start_date+i))
  .y(0)

# ------------------------------------


chart_extent = (array) ->
  full_extent = d3.extent(array)
  range = full_extent[1] - full_extent[0]
  [
    full_extent[0] - range*.1
    full_extent[1] + range*.1
  ]

get_data_in_chart_view = (series_name)->
  ts_annual[series_name].data.filter((d) -> +d.period <= end_date and +d.period >= start_date)

get_series_extent = (series_data)->
  chart_extent(series_data.map((d) -> +d.val))

combine_extent = (ex1, ex2) ->
  [ d3.min([ex1[0],ex2[0]]), d3.max([ex1[1],ex2[1]]) ]

update_domain = (series_datas, scale) ->
  return [0,1] if series_datas.length == 0
  all_data = []
  all_data = all_data.concat(series) for series in series_datas
  scale.domain(get_series_extent(all_data))

toggle_axis_button = (series, axis) ->
  button = d3.select("#s_row_#{series_to_class(series)} .#{axis}_toggle")
  if button.classed("off")
    button.text("-").attr("class", "#{axis}_toggle on")
  else
    button.text("+").attr("class", "#{axis}_toggle off")

window.add_to_line_chart = (series, axis) ->
  duration = 500
  chart_area = d3.select("g#chart_area")
  data = get_data_in_chart_view(series)
  domain = get_series_extent(data)  
  cur_domain = y[axis].scale.domain()

  unless chart_area.selectAll("path."+y[axis].class).empty()
    domain = combine_extent(cur_domain, domain)

  y[axis].scale.domain(domain).nice()

  d3.select("##{axis}_axis")
    .transition()
    .duration(duration)
    .call(y[axis].axis)

  chart_area.append("path")
    .datum(data)
    .attr("id", y[axis].class + "_#{series_to_class(series)}")
    .attr("class", "#{y[axis].class} line_chart_path")
    .attr("stroke", "#777")
    .attr("d", dummy_path)

  chart_area.selectAll("path.#{y[axis].class}")
    .transition()
    .duration(duration)
    .attr("d", y[axis].path)

  toggle_axis_button(series, axis)


window.remove_from_line_chart = (series, axis) ->
  duration = 500
  chart_area = d3.select("g#chart_area")  
  d3.select("#s_#{axis}_#{series_to_class(series)}").remove()

  update_domain(chart_area.selectAll(".#{y[axis].class}").data(), y[axis].scale)

  d3.select("##{axis}_axis")
    .transition()
    .duration(duration)
    .call(y[axis].axis)

  chart_area.selectAll("path.#{y[axis].class}")
    .transition()
    .duration(duration)
    .attr("d", y[axis].path)

  toggle_axis_button(series, axis)

  
window.line_chart = (container) ->
  svg = set_up_svg(container)
  margin = 
    top: 10
    bottom: 25
    left: 50
    right: 50

  chart_area_width = svg.attr("width") - margin.left-margin.right
  chart_area_height = svg.attr("height") - margin.top - margin.bottom

  x.rangePoints([0, chart_area_width])
  y.left.scale.range([chart_area_height,0])
  y.right.scale.range([chart_area_height,0])

  svg.append("g")
    .attr("id", "time_axis")
    .attr("transform", "translate(#{margin.left},#{margin.top+chart_area_height})")
    .call(time_axis)

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