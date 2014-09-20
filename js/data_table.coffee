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

window.create_data_table = ()->
  cat_divs = d3.select("#series_display")
    .selectAll("div.category")
    .data(d3.entries(ts_by_category))
    .enter()
    .append("div")
    .attr("class", "category")

  cat_labels = cat_divs.append("div")
    .attr("class", "cat_label")
    .attr("id",(d)->"cat_#{d.key}")
    .attr("state", "expanded")
    .text((d) -> d.key)
    .style("height", (d) -> (d.value.length * series_height) + "px")
    .style("line-height", (d) -> (d.value.length * series_height) + "px")
    .on("mouseover", (d) -> d3.select(this).style "background-color", "#999")
    .on("mouseout", (d) -> d3.selectAll(".cat_label").style "background-color", "#CCC")
    .on("click", (d) ->
      cat = d3.select(this)
      if cat.attr("state") is "expanded"
        collapse cat
      else
        expand cat
     )
     
  create_series_rows(cat_divs)

mouseover_series = (d) ->
  this_cat = d3.select(this).style("background-color", "#EEE")

mouseout_series = (d) ->
  d3.selectAll(".series")
    .style("background-color", "#FFF")
    .selectAll("div")
    
create_series_rows = (cat_divs)->
  cat_series = cat_divs.append("div")
    .attr("class", "cat_series")
    .selectAll("div.series").data((d) -> d.value)
    .enter()
    .append("div")
    .attr("id",(d) -> "s_row_#{series_to_class(d.name)}")
    .attr("class", "series")
    .style("height", series_height + "px")
    .on("mouseover", mouseover_series)
    .on("mouseout", mouseout_series)

  cat_series
    .call(create_series_label)
    .call(create_sparklines)
    .call(create_axis_controls)

create_series_label = (cat_series) ->
  cat_series.append("div")
    .attr("class", "series_label")
    .style("line-height", series_height + "px")
    .append("span")
    .text((d) -> d.name)
  
create_sparklines = (cat_series) ->
  spark_paths = cat_series.append("svg")
    .attr("class", "sparkline")
    .attr("height", series_height)
    .attr("width", 150)

  draw_sparklines [ 0, all_dates.length - 1 ], 0

create_axis_control = (cat_series, axis) ->
  cat_series.append("div")
    .attr("class", "#{axis}_toggle off")
    .text("+")
    .on("click", (d) -> 
      button = d3.select(this)
      if (button.classed("off"))
        add_to_line_chart(d.name, axis)
      else
        remove_from_line_chart(d.name, axis)
    )
  
create_axis_controls = (cat_series) ->
  cat_series
    .call(create_axis_control, "left")
    .call(create_axis_control, "right")

draw_sparklines = (extent, duration) ->
  cat_series = d3.selectAll("div.series")
  start_i = extent[0]
  end_i = extent[1]
  point = end_i - start_i
  x.domain([ 0, end_i - start_i ])

  trimmed_dates = all_dates.slice(start_i, end_i + 1)

  d3.select("#sparkline_header").text trimmed_dates[end_i - start_i]
  svg = cat_series.select("svg").datum((d) ->
    trimmed_data_object d, start_i, end_i
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
  
trimmed_data_object = (d, start_i, end_i) ->
  new_d = jQuery.extend(true, {}, d)
  new_d.spark_data = d.spark_data.slice(start_i, end_i + 1)
  y.domain d3.extent(new_d.spark_data)
  new_d.scaled_data = new_d.spark_data.map((e) -> (if e is null then null else y(e)))
  new_d

trim_sparklines = (event, ui) ->
  draw_sparklines ui.values, 0
  
set_slider_in_div = (div_id, val1, val2, slide_func) ->
  d3.select("#" + div_id).remove()
  d3.select("#" + div_id.replace("div", "container")).insert("div", "div#buttons").attr("id", div_id).attr "class", "slider"
  $("#" + div_id).slider
    range: true
    min: 0
    max: all_dates.length - 1
    values: [ val1, val2 ]
    slide: slide_func

window.set_up_sliders = ->
  set_slider_in_div "sparkline_slider_div", 0, all_dates.length - 1, trim_sparklines
