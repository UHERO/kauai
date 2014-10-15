---
---
cell_width = 50
series_height = 45
datatable_width= 300
x = d3.scale.linear().clamp(true).range([ 0, 145 ])
y = d3.scale.linear().range([ series_height, 5 ])
window.mode = "line_bar"

all_dates = ->
  d3.select("#datatable_slider_div").datum()
  
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
  cat.attr("state", "collapsed")

  d3.select(cat.node().parentNode)
    .selectAll("div.series")
    .transition()
    .style("height", "0px")

window.expand = (cat) ->
  cat.attr("state", "expanded")

  d3.select(cat.node().parentNode)
    .selectAll("div.series")
    .filter((d) ->
      row = d3.select(this)
      collapsed = row.attr("state") == "collapsed"
      child = row.classed("child")
      not child or not collapsed
    )
    .transition()
    .style("height", series_height + "px")
  

class_name_from_series_node = (node) ->
  return series_to_class(node.datum().udaman_name)
    
window.collapse_series = (series) ->
  series.attr("state", "collapsed")
  d3.selectAll(".child_of_#{class_name_from_series_node(series)}")
    .transition()
    .style("height", "0px")
    .attr("state", "collapsed")
    
window.expand_series = (series) ->
  series.attr("state", "expanded")
  d3.selectAll(".child_of_#{class_name_from_series_node(series)}")
    .transition()
    .style("height", series_height + "px")
    .attr("state", "expanded")

s_row = (udaman_name) ->
  return d3.select("#s_row_#{series_to_class(udaman_name)}")
    
click_cat = (d) ->
  cat = d3.select(this)
  if cat.attr("state") is "expanded"
    collapse cat
  else
    expand cat

# also add in a way to switch to right axis here
click_series = (d) ->
  series = d3.select(this)
  if series.classed("selected") then clear_series(series) else add_series(series)

click_expander = (d) ->
  series = s_row(d.udman_name)
  if series.attr("state") is "expanded"
    collapse_series series
  else
    expand_series series
        
mouseover_series = (d) ->
  d3.select(this).classed("hovered", true)

mouseout_series = (d) ->
  d3.selectAll(".series").classed("hovered", false)

window.highlight_series_row = (d) ->
  s_row(d.udaman_name).classed("selected", true)
  
window.unhighlight_series_row = (d) ->
  s_row(d.udaman_name).classed("selected", false)
  
add_series = (series) ->
  d = series.datum()
  current_selection = d3.selectAll(".series.selected")
  sel_count = current_selection.data().length

  highlight_series_row(d)

  switch sel_count
    when 0 then display_line_and_bar_chart(d)
    when 1 then line_and_bar_to_multi_line(d)
    else add_to_line_chart(d, "left")

clear_series= (series) ->
  d = series.datum()
  current_selection = d3.selectAll(".series.selected")
  sel_count = current_selection.data().length

  unhighlight_series_row(d)

  switch sel_count
    when 1 then clear_line_and_bar_chart(d)
    when 2 then multi_line_to_line_and_bar(d)
    else clear_from_line_chart(d)
  
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

#change this
#window.trim_sparklines = (event, ui) ->
window.trim_sparklines = (event) ->
  ui =
    values: $("#sparkline_slider_div").val()
  d3.select("h3#date_series_left").text(all_dates()[ui.values[0]])
  d3.select("h3#date_series_right").text(all_dates()[ui.values[1]])
  if d3.select("#sparkline_slider_div a.ui-state-focus").attr("slider") == "left"
    text = d3.select("#sparkline_slider_div a.ui-state-focus").style("left").split("px")
    d3.select("h3#date_series_left").style("left", (parseInt(text[0]) - 20) + "px")
  
  if d3.select("#sparkline_slider_div a.ui-state-focus").attr("slider") == "right"
    text = d3.select("#sparkline_slider_div a.ui-state-focus").style("left").split("px")
    d3.select("h3#date_series_right").style("left", (parseInt(text[0]) - 20) + "px")
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
    
window.slide_table = (event, ui) ->
  text = d3.select("#datatable_slider_div a").style("left").split("px")
  d3.select("h3#date_table").text(all_dates()[ui.value]).style("left", (parseInt(text) + 400) + "px")
  offset_val = ui.value+1
  offset= -(offset_val * cell_width - datatable_width)
  d3.selectAll(".container")
    .transition()
    #.duration(200)
    .style("margin-left", offset+"px")

populate_dates = ->
  container = d3.select("#datatable_header")
    .append("div")
    .attr("class", "container")
    .style("width", (all_dates().length*cell_width)+"px")
    .style("margin-left", -(all_dates().length*cell_width-datatable_width)+"px")
    
  container.selectAll("div.cell")
    .data(all_dates())
    .enter()
    .append("div")
    .attr("class", "cell")
    .text((d) -> d)

create_data_columns = (cat_series) ->
  container = cat_series.append("div")
    .attr("class", "data_cols")
    .append("div")
    .attr("class", "container")
    .style("width", (d) -> (d[freq].data.length*cell_width)+"px")
    .style("margin-left", (d) -> -(d[freq].data.length*cell_width-datatable_width)+"px")
    
  container.selectAll("div.cell")
    .data((d) -> d[freq].data)
    .enter()
    .append("div")
    .attr("class", "cell")
    .text((d) -> (+d).toFixed(3))
      
create_axis_control = (cat_series, axis) ->
  cat_series.append("div")
    .attr("class", "#{axis}_toggle off")
    #.text(".")
    .text("+")
    .on("click", (d) -> 
      d3.event.stopPropagation
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

#this line seems to throw an error about slider initialization
  spark_range = $("#sparkline_slider_div").slider("option","values")
  draw_sparklines spark_range, 0
    
create_series_label = (cat_series) ->
  label = cat_series.append("div")
    .attr("class", "series_label")
    .style("line-height", series_height + "px")

  parents = label.filter((d) -> d.children_sum)
    .append("a")
    .attr("href", "javascript:;")
    .html("&nbsp; + ")
    .on("click", click_expander)
    
  label
    .append("span")
    .text((d) -> d.display_name)
      
series_row_class = (d)->
  child_class = if d.series_parent != "" then " child child_of_#{series_to_class(d.series_parent)}" else ""
  parent_class = if d.children_sum then " parent" else ""
  "series" + child_class + parent_class
    
create_series_rows = (cat_divs)->
  cat_series = cat_divs
    .selectAll("div.series")
    .data((d) -> flatten(d.series_list))
    .enter()
    .append("div")
    .attr("id",(d) -> "s_row_#{series_to_class(d.udaman_name)}")
    .attr("class", series_row_class)
    .attr("state", "expanded")
    .style("height", series_height + "px")
    .style("cursor", "pointer")
    .on("mouseover", mouseover_series)
    .on("mouseout", mouseout_series)
    .on("click", click_series)

  cat_series
    .call(create_series_label)
    .call(create_sparklines)
    .call(create_axis_controls)
    .call(create_data_columns)
    
window.create_data_table = (page_data)->
  populate_dates()
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
    .on("click", click_cat)
     
  create_series_rows(cat_divs)
