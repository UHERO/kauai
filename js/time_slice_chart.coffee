---
---
window.slice_type = "pie"
slider_val = null
svg = null
chart_area = null
max_pie = null

treemap_props = 
  width: null
  height: null
color = d3.scale.category20c()

window.treemap_layout = d3.layout.treemap()
  #.size([])
  .size([300, 300])
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
  d3.select("#slice_slider_selection").text(selected_date())
    
window.redraw_slice = (event, ui) ->
  #console.log "window.redraw_slice called"
  #slider_val = ui.value
  slider_val = +$("#time_slice_slider_div").val()
  set_date_shown()

  if window.slice_type is "pie"
    pie_slices = chart_area.selectAll("path")
    pie_data = pie_slices.data().map((d) -> d.data)
    pie_slices
      .data(pie_layout(pie_data), (d) -> d.data.display_name)
      .attr("d", pie_arc)

    chart_area.select("text.in_pie_label").remove()

    sorted_array = pie_slices.data().sort((a,b) -> a.value - b.value)
    #console.log(sorted_array)
    max_pie = sorted_array.pop()

    console.log max_pie
    chart_area.selectAll("text")
      #.data([pie_slices.data()[0]])
      .data([max_pie])
      ##.data([d])
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
      # .text(d.value.toPrecision(3)) # keep 3 significant digits
      .text((d) -> d.value.toFixed(1)) # keep one decimal place
  else
    window.node.data(treemap_layout.nodes).call treemap_position


get_data_index_extent = (data) ->
  start_i = data.findIndex((d) -> d != null)
  end_i = data.length - 1 - data.slice().reverse().findIndex((d) -> d != null)
  [start_i,end_i]
  
get_common_dates = (series_data) ->
  arr = series_data.map((series) -> get_data_index_extent series[freq].data)
  [d3.max(arr.map((d)-> d[0])), d3.min(arr.map((d)-> d[1]))]
  
mouseover_pie = (d,i) ->
  slice = d3.select(this)
  slice.attr("fill-opacity", ".3")

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
    # .text(d.value.toPrecision(3)) # keep 3 significant digits
    .text(d.value.toFixed(1)) # keep one decimal place
    
  #if max_pie.value == d.value
  chart_area.select("text.in_pie_label").remove()

mouseout_pie = (d) ->
  slice = d3.select(this)
  slice.attr("fill-opacity", "1")
  chart_area.select("text.pie_label").remove()
  #if max_pie.value == d.value 
  chart_area.selectAll("text")
    #.data([max_pie])
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
    # .text(d.value.toPrecision(3)) # keep 3 significant digits
    .text(d.value.toFixed(1)) # keep one decimal place
    #.text((d) -> d.data.display_name)
    #.style("font-size", "9px")
    #.style('font-weight', "bold")
      
set_slider_dates = (extent) ->
  slider_val = extent[1]
  # no need to change the dates, slider indices are still relative
  # to full date / data arrays
  # this causes problems when sharing the slider
  $("#time_slice_slider_div").noUiSlider({ range: {min: extent[0], max: extent[1]} }, true)
  set_date_shown()  

window.pie_these_series = (series_data) ->
  console.log "window.pie_these_series was called"
  console.log(series_data)
  if series_data[0].display_name is "Construction & Mining"
    window.slice_type = "treemap"
  else
    window.slice_type = "pie"
  data_extent = get_common_dates(series_data)
  set_slider_dates(data_extent)
  chart_area.selectAll("path").remove()

  sorted_array = pie_layout(series_data).sort((a,b) -> a.value - b.value)
  #console.log(sorted_array)
  if window.slice_type == "pie"
    max_pie = sorted_array.pop()
    chart_area.selectAll("path")
      .data(pie_layout(series_data), (d) -> d.data.display_name)
      .enter()
      .append("path")
      .attr("d", pie_arc)
      .attr("fill", (d) -> color(d.data.display_name))
      .attr("stroke", "white")
      .attr("stroke-width", 2)
      .on("mouseover", mouseover_pie)
      .on("mouseout", mouseout_pie)
    
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
    chart_area.attr("transform", "translate(0,0)")
    window.node = chart_area.datum({children: series_data}).selectAll("rect")
      .data(treemap_layout.nodes)
      .enter().append("rect")
      .call treemap_position
      .attr("fill", (d) ->
        switch d.depth
          when 2 then color(d.parent.display_name)
          when 3 then color(d.parent.parent.display_name)
          else color(d.display_name)
      )
      .on "mouseover", treemap_mousemove
      .on "mouseout", treemap_mouseout

  d3.select("#pie_heading").text($(".series.parent").first().prev().text().trim().replace("Total", ""))

treemap_mousemove = (d) ->
  xPosition = d3.event.pageX + 5
  yPosition = d3.event.pageY + 5
  console.log(d)

  d3.select "#treemap_tooltip"
    .style "left", xPosition + "px"
    .style "top", yPosition + "px"
  d3.select "#treemap_tooltip #treemap_tooltip_heading"
    .text () ->
      switch d.depth
        when 2 then "#{d.display_name} (#{d.parent.display_name})"
        when 3 then "#{d.display_name} (#{d.parent.display_name}-#{d.parent.parent.display_name})"
        else d.display_name
  d3.select("#treemap_tooltip #treemap_tooltip_percentage")
    .text( (d.area/(300*300) * 100).toFixed(1) + "%")
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
  #console.log "window.visitor_pie_chart"
  slider_val = all_dates().length-1
  svg = set_up_svg(container)

  center_x = svg.attr("width") / 2
  center_y = svg.attr("height") / 2

  treemap_props.width = svg.attr("width")
  treemap_props.height = svg.attr("height")

  svg.append("text")
    .attr("id", "pie_heading")
    .attr("text-anchor", "middle")
    .attr("x", center_x)
    .attr("y", 20)
    .text($(".cat_label").first().text().trim())


  #if window.slice_type == "pie" 
  chart_area = svg.append("g")
    .attr("id", "pie_chart_area")
    .attr("transform", "translate(#{center_x},#{center_y})")
  #else
    # make treemap
    #chart_area = svg.append("g")
      #.attr("id", "treemap_area")

  svg.append("text")
    .attr("id", "slice_slider_selection")
    .attr("text-anchor", "middle")
    .attr("x", center_x)
    .attr("y", svg.attr("height")-10)
    .text("2013")
    
