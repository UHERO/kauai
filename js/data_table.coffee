---
---
cell_width = 50
series_height = 45
datatable_width= 300
x = d3.scale.linear().clamp(true).range([ 0, 145 ])
y = d3.scale.linear().range([ series_height, 5 ])
window.mode = "line_bar"
slider_val = null #new value

all_dates = ->
  d3.select("#time_slice_slider_div").datum()

# new implementation
selected_dates = ->
    all_dates()[(slider_val-4)..slider_val]

# new implementation
selected_data = (d) ->
    yoy = d[freq].yoy[(slider_val-4)..slider_val]
    d[freq].data[(slider_val-4)..slider_val].map (d, i) ->
      {data: d, yoy: yoy[i]}
  
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
  return window.series_to_class(node.datum().udaman_name)
    
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
  return d3.select("#s_row_#{window.series_to_class(udaman_name)}")
    
click_cat = (d) ->
  cat = d3.select(this)
  if cat.attr("state") is "expanded"
    cat.select(".glyphicon").classed({"glyphicon-chevron-down": false, "glyphicon-chevron-right": true})
    collapse cat
  else
    cat.select(".glyphicon").classed({"glyphicon-chevron-down": true, "glyphicon-chevron-right": false})
    expand cat

click_series = (d) ->
  series = d3.select(this)
  #if series.classed("selected") then clear_series(series) else add_series(series)
  set_primary_series(series)
  

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

###
# this function replaces add_series and clear_series
# the new functionality allows the user to
# select the series on the left by clicking the series
# a separate button will allow them to select 
# at most one series on the right axis
###
#window.set_primary_series = (series) ->
    #set_primary_series(series)
set_primary_series = (series) ->
  #window.primary_series = series
  new_series = series.datum()
  old_series = d3.select(".series.selected").datum()
  # only do stuff if this is not already the primary series and if it is not the secondary series
  if new_series.udaman_name != old_series.udaman_name and !d3.select("g#chart_area #path_#{window.series_to_class(new_series.udaman_name)}").classed("s_right")
    # see if we are in multi_line mode or line_bar mode
    # if we are in line_and_bar, should call clear_line_and_bar_chart and display_line_and_bar_chart
    if (window.mode == "line_bar")
      unhighlight_series_row(old_series)
      highlight_series_row(new_series)
      clear_line_and_bar_chart(old_series)
      display_line_and_bar_chart(new_series)
    # if we are in multi_line, should call add_to_line_chart and clear_from_line_chart
    else
      unhighlight_series_row(old_series)
      highlight_series_row(new_series)
      window.add_to_line_chart(new_series, "left")
      window.clear_from_line_chart(old_series)



  # remove selected class from all series
  #d3.selectAll(".series").classed("selected", false)
  #series.classed("selected", true);
  #series_to_remove = d3.selectAll(".series:not(.selected)")
  #series_to_remove.each((d) -> unhighlight_series_row(d))

  ##highlight_series_row(d) # redundant next function calls this
  #line_and_bar_to_multi_line(d)
  #series_to_remove.each((d) -> multi_line_to_line_and_bar(d))
  #series_to_remove.each((d) -> clear_line_and_bar_chart(d))

#window.set_secondary_series = (series) ->
    #set_secondary_series(series)

set_secondary_series = (series) ->
  #window.secondary_series = series
  new_secondary_series = series.datum()
  # make sure secondary is not the same as primary, if it is, do nothing here
  primary_series = d3.select(".series.selected").datum()
  if new_secondary_series.udaman_name == primary_series.udaman_name
    # do nothine
  else
    # this crazy line seems necessary due to lack of a parent selector in css
    on_toggle = d3.select(".right_toggle.on").node()
    if on_toggle?
      old_secondary_series = d3.select(on_toggle.parentNode).datum()
      # switch the secondary axis, no need to change mode
      # add the new series and remove the old
      add_to_line_chart(new_secondary_series, "right")
      clear_from_line_chart(old_secondary_series)
      #
      # uncheck the old series
      d3.select(on_toggle).classed({"off": true, "on": false, "glyphicon-unchecked": true, "glyphicon-check": false})
    else
      line_and_bar_to_multi_line(new_secondary_series)

    # check the current series
    series.select(".right_toggle").classed({"off": false, "on": true, "glyphicon-unchecked": false, "glyphicon-check": true})
    # see if we are already in multi_line
    # if we are in multi_line, should call clear_from_line_chart and add_to_line_chart
    # if we are in line_bar, should call line_and_bar_to_multi_line

remove_secondary_series = (series) ->
  d = series.datum()
  # call multi_line_to_line_and_bar
  multi_line_to_line_and_bar(d)

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

window.trim_sparklines = (event) ->
  draw_sparklines $("#line_chart_slider_div").val(), 0
  
draw_sparklines = (extent, duration) ->
  cat_series = d3.selectAll("div.series")
  start_i = extent[0]
  end_i = extent[1]
  point = end_i - start_i
  x.domain([ 0, end_i - start_i ])

  dates = d3.select("#line_chart_slider_div").datum()
  trimmed_dates = dates.slice(start_i, end_i + 1)

  #d3.select("#sparkline_header").text trimmed_dates[end_i - start_i]
  #d3.select("#sparkline_header").html "&nbsp;"
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
  #text = d3.select("#datatable_slider_div a").style("left").split("px")
  #d3.select("h3#date_table").text(all_dates()[ui.value]).style("left", (parseInt(text) + 400) + "px")

  # new implementation
  slider_val = +$("#time_slice_slider_div").val()
  populate_dates()
  update_data_columns()

  offset_val = +$("#time_slice_slider_div").val() + 1
  offset= -(offset_val * cell_width - datatable_width)
  d3.selectAll(".container")
    #.transition()
    #.duration(200)
    .style("margin-left", offset+"px")

populate_dates = ->
  data = selected_dates()
  dates = d3.select("#datatable_header").selectAll(".header_cell").data data
  dates.enter()
    .append("div")
    .attr("class", "header_cell")
  dates.html((d) -> "#{d}<br/>YOY%")
  dates.exit().remove()
    
create_ytd_column = (cat_series) ->
    container = cat_series.append("div").attr("class", "ytd_cell")
      .html((d) ->
        #console.log d
        last_obs = if d[freq].last? then (+d[freq].last).toFixed(3) else ""
        last_date = if d[freq].last? then d[freq].date[d[freq].last_i] else ""
        last_ytd_change_num = +d[freq].ytd_change[d[freq].last_i]
        last_ytd_change = (last_ytd_change_num).toFixed(2) + "%"
        sign = if last_ytd_change_num > 0 then " pos" else " neg"
        "<span class=\"last_obs\">#{last_obs}</span><span class=\"last_date\">#{last_date}</span><span class=\"ytd_change#{sign}\">#{last_ytd_change}</span>"
      )

window.update_ytd_column = (event) ->
    last_index = ($("#line_chart_slider_div").val().map (value) -> +value)[1]
    d3.selectAll(".ytd_cell").html((d) ->
        last_obs = if d[freq].data[last_index]? then (+d[freq].data[last_index]).toFixed(3) else ""
        last_date = if d[freq].data[last_index]? then d[freq].date[last_index] else ""
        if not d[freq].data[last_index]? or isNaN d[freq].ytd_change[last_index]
          last_ytd_change = "&nbsp;"
          sign = ""
        else
          last_ytd_change = (+d[freq].ytd_change[last_index]).toFixed(2) + "%"
          sign = if +d[freq].ytd_change[last_index] > 0 then " pos" else " neg"
        #last_ytd_change_num = if d[freq].ytd_change[last_index]? then +
        #last_ytd_change = (last_ytd_change_num).toFixed(2) + "%"
        #sign = if last_ytd_change_num > 0 then " pos" else " neg"
        "<span class=\"last_obs\">#{last_obs}</span><span class=\"last_date\">#{last_date}</span><span class=\"ytd_change#{sign}\">#{last_ytd_change}</span>"
    )
    

create_data_columns = (cat_series) ->
  container = cat_series.append("div")
    .attr("class", "data_cols")
    #.append("div")
    #.attr("class", "container")
    #.style("width", (d) -> (d[freq].data.length*cell_width)+"px")
    #.style("margin-left", (d) -> -(d[freq].data.length*cell_width-datatable_width)+"px")
    
  container.selectAll("div.cell")
    .data((d) ->
        selected_data(d))
    .enter()
    .append("div")
    .attr("class", "cell")
    .html (d) ->
      data = if d.data? then (+d.data).toFixed(3) else ""
      yoy = if d.yoy? then (+d.yoy).toFixed(2) + "%" else ""
      yoy = if d.yoy > 0 then "+#{yoy}" else yoy
      sign = if d.yoy > 0 then " pos" else (if d.yoy < 0 then " neg" else "")
      "<span class=\"cell_value\">#{data}</span><span class=\"cell_yoy#{sign}\">#{yoy}</span>"

update_data_columns = () ->
    cat_series = d3.selectAll("div.series")
    container = cat_series.selectAll(".data_cols")

    cells = container.selectAll("div.cell")
      .data (d) -> selected_data(d)
    cells.enter().append("div").attr("class", "cell")
    #cells.text (d) -> if d? then (+d).toFixed(3) else ""
    cells.html (d) ->
      data = if d.data? then (+d.data).toFixed(3) else ""
      yoy = if d.yoy? then (+d.yoy).toFixed(2) + "%" else ""
      yoy = if d.yoy > 0 then "+#{yoy}" else yoy
      sign = if d.yoy > 0 then " pos" else (if d.yoy < 0 then " neg" else "")
      "<span class=\"cell_value\">#{data}</span><span class=\"cell_yoy#{sign}\">#{yoy}</span>"
    #d3.selectAll("div.series").selectAll('.cell').data()
    #data = selected_data cat_series.data()
    #container = cat_series.selectAll(".data_cols")
    #cells = container.selectAll("div.data_cell")
      #.data data
    #cells.enter()
      #.append("div")
      #.attr("class", "cell")
    #cells.text((d) ->
      #if d? then (+d).toFixed(3) else "")
    #cells.exit().remove()
      
create_axis_control = (cat_series, axis) ->
  #cat_series.append("div")
  cat_series.append("span")
    .attr("class", "#{axis}_toggle off glyphicon glyphicon-unchecked")
    #.text(".")
    #.text("+")
    .on("click", (d) -> 
      d3.event.stopPropagation()
      button = d3.select(this)
      if (button.classed("off"))
        #button.classed({"off": false, "on": true, "glyphicon-unchecked": false, "glyphicon-check": true})
        set_secondary_series(d3.select(button.node().parentNode))
        #add_to_line_chart(d, axis)
      else
        #remove_from_line_chart(d, axis)
        button.classed({"off": true, "on": false, "glyphicon-unchecked": true, "glyphicon-check": false})
        remove_secondary_series(d3.select(button.node().parentNode))

)

create_axis_controls = (cat_series) ->
  cat_series
    #.call(create_axis_control, "left")
    .call(create_axis_control, "right")

create_sparklines = (cat_series) ->
  spark_paths = cat_series.append("svg")
    .attr("class", "sparkline")
    .attr("height", series_height)
    .attr("width", 150)

  #this line seems to throw an error about slider initialization
  spark_range = $("#line_chart_slider_div").val()
  draw_sparklines spark_range, 0
    
create_series_label = (cat_series) ->
  label = cat_series.append("div")
    .attr("class", "series_label")
    .style("line-height", series_height + "px")

  #parents = label.filter((d) -> d.children_sum)
    #.append("a")
    #.attr("href", "javascript:;")
    #.html("&nbsp; + ")
    #.on("click", click_expander)
    
  label
    .append("span")
    .text((d) -> d.display_name)
      
series_row_class = (d)->
  child_class = if d.series_parent != "" then " child child_of_#{window.series_to_class(d.series_parent)}" else ""
  parent_class = if d.children_sum then " parent" else ""
  "series" + child_class + parent_class
    
create_series_rows = (cat_divs)->
  cat_series = cat_divs
    .selectAll("div.series")
    .data((d) -> flatten(d.series_list))
    .enter()
    .append("div")
    .attr("id",(d) -> "s_row_#{window.series_to_class(d.udaman_name)}")
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
    .call(create_ytd_column)
    .call(create_data_columns)
    
window.create_data_table = (page_data)->
  slider_val = all_dates().length - 1
  populate_dates()
  cat_divs = d3.select("#series_display")
    .selectAll("div.category")
    .data(page_data.series_groups)
    .enter()
    .append("div")
    .attr("class", "category")

  cat_labels = cat_divs.append("div")
    .attr("class", "cat_label")
    .attr("id",(d)->"cat_#{window.series_to_class(d.group_name)}")
    .attr("state", "expanded")
    .html((d) -> 
      "<span class='glyphicon glyphicon-chevron-down'></span> #{d.group_name.replace('Total ','')}")
    #.text((d) -> d.group_name)
    .on("mouseover", (d) -> d3.select(this).style "background-color", "#999")
    .on("mouseout", (d) -> d3.selectAll('.cat_label').style "background-color", "#FFF")
    .on("click", click_cat)
     
  create_series_rows(cat_divs)
