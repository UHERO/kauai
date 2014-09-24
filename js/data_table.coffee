---
---

series_height = 45;
x = d3.scale.linear().clamp(true).range([ 0, 145 ])
y = d3.scale.linear().range([ series_height, 5 ])

spark_line = d3.svg.line()
  .x((d, i) -> x i)
  .y((d) -> d)
  .defined((d) -> d isnt null)

spark_area_path = d3.svg.area()
  .x((d, i) -> x i)
  .y1((d) -> d)
  .y0(series_height)
  .defined((d) -> d isnt null)
  
window.collapse = (cat) ->
  cat.transition()
    .style("height", series_height + "px")
    .style("line-height", series_height + "px")
    .attr "state", "collapsed"

  d3.select(cat.node().parentNode)
    .selectAll("div.series")
    .transition()
    .style "height", (d) -> (if d.primary is "Primary" then series_height + "px" else "0px")

window.expand = (cat) ->
  cat.transition()
    .style("height", (d) -> (d.value.length * series_height) + "px")
    .style("line-height", (d) ->(d.value.length * series_height) + "px")
    .attr "state", "expanded"

  d3.select(cat.node().parentNode)
    .selectAll("div.series")
    .transition()
    .style "height", series_height + "px"
  


  

  







#---- New Keeper Stuff ------
mouseover_series = (d) ->
  this_cat = d3.select(this).style("background-color", "#EEE")

mouseout_series = (d) ->
  d3.selectAll(".series")
    .style("background-color", "#FFF")
    .selectAll("div")

add_parent = (series_data, parent) ->
  series_data.series_parent = parent
  series_data
  
flatten_children = (series_data) ->
  series_list = []
  series_list.push add_parent(series_data, "")
  (series_list.push add_parent(series, series_data.udaman_name) for series in series_data.children) if series_data.children?
  series_list
  
flatten = (series_list) ->
  new_list = []
  new_list = new_list.concat(flatten_children series) for series in series_list
  new_list

trimmed_data_object = (d, start_i, end_i) ->
  new_d = jQuery.extend(true, {}, d)
  new_d.spark_data = d.data.slice(start_i, end_i + 1)
  y.domain d3.extent(new_d.spark_data)
  new_d.scaled_data = new_d.spark_data.map((e) -> (if e is null then null else y(e)))
  new_d

window.trim_sparklines = (event, ui) ->
  draw_sparklines ui.values, 0
  
draw_sparklines = (extent, duration) ->
  cat_series = d3.selectAll("div.series")
  start_i = extent[0]
  end_i = extent[1]
  point = end_i - start_i
  x.domain([ 0, end_i - start_i ])

  dates = d3.select("#sparkline_slider_div").datum()
  trimmed_dates = dates.slice(start_i, end_i + 1)

  d3.select("#sparkline_header").text trimmed_dates[end_i - start_i]
  svg = cat_series.select("svg").datum((d) ->
    trimmed_data_object d[freq], start_i, end_i
  )
  draw_spark_path svg, duration
  draw_spark_area svg, duration

draw_spark_path = (svg, duration) ->
  spark_path = svg.selectAll("path.spark")
    .data( (d) -> [ d.scaled_data ] )

  spark_path
    .enter()
    .append("path")
    .attr("class", "spark")
    .attr("stroke", "#3182bd")
    .attr "fill", "none"

  spark_path
    .transition()
    .duration(duration)
    .attr "d", spark_line

draw_spark_area = (svg, duration) ->
  spark_area = svg.selectAll("path.spark_area")
    .data((d) -> [ d.scaled_data ])

  spark_area
    .enter()
    .append("path")
    .attr("class", "spark_area")
    .attr("stroke", "none")
    .attr("fill", "#3182bd")
    .attr "fill-opacity", .1

  spark_area
    .transition()
    .duration(duration)
    .attr "d", spark_area_path

create_axis_control = (cat_series, axis) ->
  cat_series.append("div")
    .attr("class", "#{axis}_toggle off")
    .text("+")
    .on("click", (d) -> 
      button = d3.select(this)
      if (button.classed("off"))
        add_to_line_chart(d, axis)
      else
        remove_from_line_chart(d, axis)
    )

create_axis_controls = (cat_series) ->
  cat_series
    .call(create_axis_control, "left")
    .call(create_axis_control, "right")
    
create_sparklines = (cat_series) ->
  spark_paths = cat_series.append("svg")
    .attr("class", "sparkline")
    .attr("height", series_height)
    .attr("width", 150)

  spark_range = $("#sparkline_slider_div").slider("option","values")
  draw_sparklines spark_range, 0
    
create_series_label = (cat_series) ->
  cat_series.append("div")
    .attr("class", "series_label")
    .style("line-height", series_height + "px")
    .append("span")
    .text((d) -> d.display_name)
      
create_series_rows = (cat_divs)->
  cat_series = cat_divs
    # .append("div")
    # .attr("class", "cat_series")
    .selectAll("div.series")
    .data((d) -> flatten(d.series_list))
    .enter()
    .append("div")
    .attr("id",(d) -> "s_row_#{series_to_class(d.udaman_name)}")
    .attr("class", "series")
    .style("height", series_height + "px")
    # .on("mouseover", mouseover_series)
    # .on("mouseout", mouseout_series)

  cat_series
    .call(create_series_label)
    .call(create_sparklines)
    .call(create_axis_controls)

window.create_data_table = (page_data)->
  cat_divs = d3.select("#series_display")
    .selectAll("div.category")
    .data(page_data.series_groups)
    .enter()
    .append("div")
    .attr("class", "category")

  cat_labels = cat_divs.append("div")
    .attr("class", "cat_label")
    .attr("id",(d)->"cat_#{series_to_class(d.group_name)}")
    .attr("state", "expanded")
    .text((d) -> d.group_name)
    .on("mouseover", (d) -> d3.select(this).style "background-color", "#999")
    .on("mouseout", (d) -> d3.selectAll('.cat_label').style "background-color", "#FFF")
    .on("click", (d) ->
      cat = d3.select(this)
      if cat.attr("state") is "expanded"
        collapse cat
      else
        expand cat
     )
     
  create_series_rows(cat_divs)
