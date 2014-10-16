---
---
# ------- overal context variables ------------
window.freq = "q"
#-------- used by several modules -------------  

window.series_to_class = (series_name) ->
  series_name.replace(".","_").replace("@","_").replace("%","pct").replace(" ", "_")

window.set_up_svg = (container) ->
  width = +container.style("width").slice(0,-2)
  height = +container.style("height").slice(0,-2)
  container
    .append("svg")
    .attr("id", container.attr("id")+"_svg")
    .attr("height", height)
    .attr("width", width)

#-------- page setup methods -------------  
set_up_nav = () ->
  d3.select("div#nav")
    .selectAll("div.nav_link")
    .data(d3.entries(data_categories))
    .enter()
    .append("div")
    .attr("class", "nav_link")
    .attr("id", (d) -> d.key.replace(" ", "_"))
    .style("width", (d) -> d.value.width+"px")
    .text((d) -> d.key)
    .on("click", (d) -> load_page(d.value))

set_headline = (text) ->
  d3.select("#headline").text(text)



set_slider_in_div = (div_id, dates, pos1, pos2, slide_func) ->
  d3.select("#" + div_id).remove()
  # sneaky select of *_slider_container here
  d3.select("#" + div_id.replace("div", "container")).insert("div", "div#buttons").attr("id", div_id).attr "class", "slider"
  # instantiate the noUISlider
  $("#" + div_id).noUiSlider
    start: [ pos1,pos2 ]
    range:
      min: 0
      max: dates.length-1
    step: 1
    connect: true

  #console.log("hi")
  $("#" + div_id).on "slide", slide_func
  #console.log("there")

  d3.select("#" + div_id).datum(dates)
  #d3.selectAll("#" + div_id + " a").data([1,2]).attr("slider", (d) -> 
    #if d == 1  
      #return "left" 
    #if d == 2 
      #return "right")
  
  #adding some pips
  $("#" + div_id).noUiSlider_pips
    mode: 'range'
    density: 3

set_single_slider_in_div = (div_id, dates, pos1, pos2, slide_func) ->
  d3.select("#" + div_id).remove()
  d3.select("#" + div_id.replace("div", "container")).insert("div", "div#buttons").attr("id", div_id).attr "class", "slider"
  $("#" + div_id).slider
    min: 0
    max: dates.length-1
    value: pos2
    slide: slide_func

  d3.select("#" + div_id).datum(dates)
  
set_up_sliders = (dates)->
  set_slider_in_div "sparkline_slider_div", dates, 0, dates.length-1, trim_sparklines
  set_slider_in_div "line_chart_slider_div", dates, 0, dates.length-1, trim_time_series #DT took this out
  set_single_slider_in_div "time_slice_slider_div", dates, 0, dates.length-1, redraw_slice
  set_single_slider_in_div "datatable_slider_div", dates, 0, dates.length-1, slide_table

set_up_div = (elem) ->
  d3.select("#charts_area")
    .append("div")
    .attr("class", "dashboard_element")
    .attr("id", elem.id)
    .style("width", elem.width+"px")
    .style("height", elem.height+"px")
    .call(elem.type_function)

set_up_dashboard_elements = (elements) ->
  set_up_div elem for elem in elements
       
page_setup = () ->
  collapse d3.select("#cat_Construction")
  collapse d3.select("#cat_Employment")
  collapse d3.select("#cat_General")
  collapse d3.select("#cat_Income")

clear_dashboard_elements = ->
  d3.selectAll("#charts_area .dashboard_element").remove()
  
clear_data_table = ->
  d3.selectAll("#series_display .category").remove()
  
clear_sliders = ->
  set_slider_in_div "sparkline_slider_div", dates, 0, dates.length-1, trim_sparklines
  set_slider_in_div "line_chart_slider_div", dates, 0, dates.length-1, trim_time_series #DT took this out
  set_single_slider_in_div "time_slice_slider_div", dates, 0, dates.length-1, redraw_slice
  set_single_slider_in_div "datatable_slider_div", dates, 0, dates.length-1, slide_table
  
  
clear_previous_page = ->
  clear_dashboard_elements()
  clear_data_table()
  # don't need to clear sliders because they already clear themselves. 
  # Possibly move that in here if it doesn't break things
  
render_page = (page_data) ->
  clear_previous_page()
  #maybe fix sliders so they correspond to panel sizes
  set_up_sliders(page_data.dates[freq])

  dashboard_elements = [ 
    { id: "line_chart", width: 425, height: 300, type_function: line_chart },
    { id: "pie_chart", width: 300, height: 300, type_function: visitor_pie_chart }
  ]
  
  set_up_dashboard_elements(dashboard_elements)
  create_data_table(page_data)
  set_up_line_chart_paths(d3.selectAll("#series_display .series").data())
  
  # add_to_line_chart(page_data.series_groups[0].series_list[0], "left")
  display_line_and_bar_chart(page_data.series_groups[0].series_list[0])
  pie_these_series(page_data.series_groups[0].series_list[0].children)
  
window.load_page = (data_category) ->
  # this takes some time to load, so put in page loading graphic
  load_page_data(data_category.slug, (data) ->
    set_headline(data_category.title)
    render_page(data)
  )

#-------- main run code -------------  
set_up_nav()
load_page(data_categories["visitor industry"])



