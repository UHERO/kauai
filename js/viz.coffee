---
---
# ------- overal context variables ------------
window.freq = "q"
current_data_category = {}
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
    .text((d) -> d.value.title)
    .on("click", (d) -> load_page(d.value, true)) #click here to load a different page

set_headline = (text) ->
  d3.select("#headline").text(text)
  #dt: maybe this shouldn't be here, can move later:
  d3.select("div#nav").selectAll("div.nav_link").style("background-color",null) #reset
  current_nav_item = text.split(' ').join('_').toLowerCase()
  d3.select("#"+current_nav_item).style("background-color","#ecffc7") #$neon_green

set_slider_in_div = (div_id, dates, pos1, pos2, slide_func) ->
  d3.select("#" + div_id).remove()
  # sneaky select of *_slider_container here
  d3.select("#" + div_id.replace("div", "container")).insert("div", "div#buttons").attr("id", div_id).attr "class", "slider"
  # instantiate the noUISlider
  $("#" + div_id).noUiSlider
    start: [ pos1,pos2 ]
    behaviour: "tap-drag"
    range:
      min: 0
      max: dates.length-1
    step: 1
    connect: true

  $("#" + div_id).on "slide", slide_func

  d3.select("#" + div_id).datum(dates)

set_single_slider_in_div = (div_id, dates, pos1, pos2, slide_func) ->
  d3.select("#" + div_id).remove()
  d3.select("#" + div_id.replace("div", "container")).insert("div", "div#buttons").attr("id", div_id).attr "class", "slider"
  # instantiate the noUiSlider
  $("#" + div_id).noUiSlider
    start: dates.length-2
    range:
      min: 5
      max: dates.length-2
    step:1

  $("#" + div_id).on "slide", slide_func
  
  d3.select("#" + div_id).datum(dates)
  
set_up_sliders = (dates)->
  set_slider_in_div "line_chart_slider_div", dates, 0, dates.length-1, left_slider_func
  set_single_slider_in_div "time_slice_slider_div", dates, 0, dates.length-2, right_slider_func

left_slider_func = (event)->
  window.trim_sparklines(event)
  window.trim_time_series(event)
  window.update_ytd_column(event)

right_slider_func = (event)->
  window.redraw_slice(event)
  window.slide_table(event)

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
  set_slider_in_div "line_chart_slider_div", dates, 0, dates.length-1, left_slider_func
  set_single_slider_in_div "time_slice_slider_div", dates, 0, dates.length-1, redraw_slice
  set_single_slider_in_div "datatable_slider_div", dates, 0, dates.length-1, slide_table
  
  
clear_previous_page = ->
  window.remove_secondary_series(window.secondary_series) if window.secondary_series? and window.secondary_series.datum? and window.mode == 'multi_line'
  clear_dashboard_elements()
  clear_data_table()
  # don't need to clear sliders because they already clear themselves. 
  # Possibly move that in here if it doesn't break things

render_page = (page_data, page_slug) ->
  clear_previous_page()
  #maybe fix sliders so they correspond to panel sizes
  console.log("render page at frequency: #{window.freq}")
  set_up_sliders(page_data.dates[window.freq])

  make_slice = false
  window.pied = false
  for series_group in page_data.series_groups
    do (series_group) ->
      make_slice = true if series_group.series_list[0].children?
  
  if page_slug is 'major'
    console.log 'major page here'
    make_slice = true
  
  if make_slice
    # include pie_chart
    d3.select("#time_slice_slider_container").style("float", "left").style("margin-right", 0).style("margin-bottom", 0)
    d3.select("#line_chart_slider_container").style("width", "330px")
    dashboard_elements = [
      { id: "line_chart", width: 425, height: 300, type_function: line_chart },
      { id: "pie_chart", width: 300, height: 300, type_function: visitor_pie_chart }
    ]
    set_up_dashboard_elements(dashboard_elements)
    create_data_table(page_data)
    set_up_line_chart_paths(d3.selectAll("#series_display .series").data())
    
    # add_to_line_chart(page_data.series_groups[0].series_list[0], "left")
    window.display_line_and_bar_chart(page_data.series_groups[0].series_list[0])
    # identify the first series with children
    series_to_pie = []
    # goes through each series group
    for series_group in page_data.series_groups
      do (series_group)->
        # and pies the first group
        if page_slug isnt 'major'
          if series_group.series_list[0].children? and window.pied == false
            window.pie_these_series series_group.series_list[0].children
            window.pied= true
        else
          # add series to be pied
          for series in series_group.series_list
            series_to_pie.push(series) if series.udaman_name in ['Y_RCY@KAU', 'VDAY@KAU', 'E_NF@KAU'] #instead of KPPRVRSD_R@KAU
    if page_slug is 'major'
      window.pied = true
      window.pie_these_series series_to_pie, true
  else
    # update css for sliders
    d3.select("#time_slice_slider_container").style("float", "right").style("margin-right", "20px").style("margin-bottom", "20px")
    d3.select("#line_chart_slider_container").style("width", "648px")
    # make line chart take up entire width
    dashboard_elements = [{id: "line_chart", width: 740, height: 300, type_function: line_chart}]
    set_up_dashboard_elements(dashboard_elements)
    create_data_table(page_data)
    set_up_line_chart_paths(d3.selectAll("#series_display .series").data())
    
    window.display_line_and_bar_chart(page_data.series_groups[0].series_list[0])
  
load_page = (data_category, use_default_freq) ->
  if use_default_freq
    window.freq = data_category.default_freq
    $("#frequency_controls span.selected").removeClass("selected")
    $("#frequency_controls span").addClass("enabled")
    $("#freq_#{window.freq}").removeClass("enabled")
    $("#freq_#{window.freq}").addClass("selected")
  # this takes some time to load, so put in page loading graphic
  #console.log "slug: #{data_category.slug}"
  #console.log "title: #{data_category.title}"
  current_data_category = data_category
  window.load_page_data(data_category.slug, (data) ->
    set_headline(data_category.title)
    render_page(data, data_category.slug)
  )
  #dt edit --- to manually gray out the options w/ no data:
  # Personal Income Q/M, County Budget Q/M, Construction M
  if data_category.title == "Personal Income" || data_category.title == "County Budget" || data_category.title == "Major Indicators"
    $("#freq_q").removeClass("enabled")
    $("#freq_m").removeClass("enabled")
  else if data_category.title == "Construction"
    $("#freq_m").removeClass("enabled")

  #dt edit -- to add data sources based on page. Hides div unless on target page.
  #There's prob a better way to do this
  d3.selectAll("#data_sources").selectAll("div").style("visibility","hidden").style("height",0)

  switch data_category.title
    when "Major Indicators" then d3.select("#data_source_maj").style("visibility","visible").style("height","auto")
    when "Visitor Industry" then d3.select("#data_source_vis").style("visibility","visible").style("height","auto")
    when "Labor Market" then d3.select("#data_source_lab").style("visibility","visible").style("height","auto")
    when "Personal Income" then d3.select("#data_source_per").style("visibility","visible").style("height","auto")
    when "Construction" then d3.select("#data_source_con").style("visibility","visible").style("height","auto")
    when "County Budget" then d3.select("#data_source_bud").style("visibility","visible").style("height","auto")

#-------- main run code -------------  
set_up_nav()
load_page(data_categories["visitor industry"])
$("#frequency_controls span").addClass("enabled")
$("#freq_q").removeClass("enabled").addClass("selected")

# event listener for switching frequency
$("#frequency_controls span").on("click", () ->
    if $(this).hasClass("enabled")
      # grab the currently selected primary series and secondary series
      $("#frequency_controls span.selected").removeClass("selected")
      window.freq = $(this).text().toLowerCase()
      load_page(current_data_category)

      #--
      ###
      current_page = current_data_category.title
      if current_page == "Visitor Industry"
        console.log("TRUE")
      else
        console.log("FALSE")
      ###
      #--

      $("#frequency_controls span").addClass("enabled")
      $(this).removeClass("enabled")
      $(this).addClass("selected")
)

# event listener for export link
$("#export").on("click", () ->
  window.location.href = "export_data/#{current_data_category.slug}_#{window.freq}_export.csv"
)
# event listener for reset link
$("#reset").on("click", () ->
  window.remove_secondary_series(window.secondary_series) if window.secondary_series? and window.secondary_series.datum? and window.mode == 'multi_line'
  load_page(current_data_category)
)
