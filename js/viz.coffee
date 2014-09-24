---
---
# ------- overal context variables ------------
window.freq = "q"
#-------- used by several modules -------------  

window.series_to_class = (series_name) ->
  series_name.replace(".","_").replace("@","_").replace("%","pct")

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

set_headline = (text) ->
  d3.select("#headline").text(text)

set_up_dashboard_elements = (elements) ->
  set_up_div elem for elem in elements

set_slider_in_div = (div_id, dates, pos1, pos2, slide_func) ->
  d3.select("#" + div_id).remove()
  d3.select("#" + div_id.replace("div", "container")).insert("div", "div#buttons").attr("id", div_id).attr "class", "slider"
  $("#" + div_id).slider
    range: true
    min: 0
    max: dates.length - 1
    values: [ pos1, pos2 ]
    slide: slide_func

  d3.select("#" + div_id).datum(dates)

set_up_sliders = (dates)->
  set_slider_in_div "sparkline_slider_div", dates, 0, dates.length-1, trim_sparklines
  set_slider_in_div "line_chart_slider_div", dates, 0, dates.length-1, trim_time_series

set_up_div = (elem) ->
  d3.select("#charts_area")
    .append("div")
    .attr("class", "dashboard_element")
    .attr("id", elem.id)
    .style("width", elem.width+"px")
    .style("height", elem.height+"px")
    .call(elem.type_function)
 
page_setup = () ->
  collapse d3.select("#cat_Construction")
  collapse d3.select("#cat_Employment")
  collapse d3.select("#cat_General")
  collapse d3.select("#cat_Income")

render_loaded_data = (data) ->
  prepare_annual_data(data)
  

render_page = (page_data) ->
  set_up_sliders(page_data.dates[freq])

  dashboard_elements = [ 
    { id: "line_chart", width: 425, height: 300, type_function: line_chart },
    { id: "pie_chart", width: 300, height: 300, type_function: visitor_pie_chart }
  ]
  
  set_up_dashboard_elements(dashboard_elements)
  create_data_table(page_data)
  
window.load_page = (page_slug) ->
  load_page_data(page_slug, (data) ->
    render_page(data)
  )

#-------- main run code -------------  
set_up_nav()
set_headline("In 2013, per person per trip spending increaed by 9.63% compared to the previous year")
d3.csv("data/kauai_data_annual.csv", render_loaded_data)

load_page("vis")