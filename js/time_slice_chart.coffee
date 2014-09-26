---
---
window.add_to_pie = (series) ->
  console.log("sending to right")

window.remove_from_pie = (series) ->
  console.log("removing from left")

window.redraw_slice = (event, ui) ->
  console.log(ui)
  
window.visitor_pie_chart = (container) ->
  svg = set_up_svg(container)
  color = d3.scale.category20c()

  center_x = svg.attr("width") / 2
  center_y = svg.attr("height") / 2

  pie_layout = d3.layout.pie()
    .value((d) -> d.val)

  pie_arc = d3.svg.arc()
    .outerRadius(100)
    .innerRadius(0)
  chart_area = svg.append("g")
    .attr("id", "pie_chart_area")
    .attr("transform", "translate(#{center_x},#{center_y})")
  pie_data = ["VISUSW", "VISUSE", "VISJP", "VISCAN"].map((d) -> 
    data_point = ts_annual["#{d}@KAU.A"].data.filter((d) -> +d.period == 2013)[0].val
    { val: +data_point, s_name: d }
  )

  svg.append("text")
    .attr("id", "slice_slider_selection")
    .attr("text-anchor", "middle")
    .attr("x", center_x)
    .attr("y", svg.attr("height")-10)
    .text("2013")
    
  chart_area.selectAll("path")
    .data(pie_layout(pie_data))
    .enter()
    .append("path")
    .attr("d", pie_arc)
    .attr("fill", (d) -> color(d.data.s_name))
    .attr("stroke", "white")
    .attr("stroke-width", 2)
    .on("mouseover", (d,i) ->
      slice = d3.select(this)
      slice.attr("fill-opacity", ".3")

      chart_area.append("text.pie_label")
        .attr("pie_label")
        .attr("text-anchor", "middle")
        .attr("transform", "translate( #{pie_arc.centroid(d)} )" )
        .text(d.data.s_name)
    )
    .on("mouseout", (d) -> 
      slice = d3.select(this)
      slice.attr("fill-opacity", "1")
      chart_area.select("text.pie_label").remove()
    )