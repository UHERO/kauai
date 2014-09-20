---
---

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
  
  dashboard_elements = [ 
    { id: "line_chart", width: 425, height: 300, type_function: line_chart },
    { id: "pie_chart", width: 300, height: 300, type_function: visitor_pie_chart },
  ]
  
  set_up_dashboard_elements(dashboard_elements)
  create_data_table()
  set_up_sliders()
  page_setup()


#-------- main run code -------------  
set_up_nav()
set_headline("In 2013, per person per trip spending increaed by 9.63% compared to the previous year")
d3.csv("data/kauai_data_annual.csv", render_loaded_data)
