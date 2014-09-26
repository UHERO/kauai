(function() {
  var all_dates, chart_area, color, dates_extent, pie_arc, pie_data, pie_data_from_series, pie_layout, selected_date, selected_pos, slider_dates, slider_extent, svg;

  slider_extent = null;

  svg = null;

  chart_area = null;

  color = d3.scale.category20c();

  pie_data = null;

  pie_layout = d3.layout.pie().value(function(d) {
    return d.vals[selected_pos()];
  });

  pie_arc = d3.svg.arc().outerRadius(100).innerRadius(0);

  window.add_to_pie = function(series) {
    return console.log("sending to right");
  };

  window.remove_from_pie = function(series) {
    return console.log("removing from left");
  };

  all_dates = function() {
    return d3.select("#time_slice_slider_div").datum();
  };

  dates_extent = function(extent) {
    return all_dates().slice(extent[0], extent[1] + 1);
  };

  slider_dates = function() {
    var extent;
    extent = slider_extent;
    return dates_extent(extent);
  };

  selected_date = function() {
    return all_dates()[selected_pos()];
  };

  selected_pos = function() {
    return slider_extent[1];
  };

  window.redraw_slice = function(event, ui) {
    slider_extent = ui.values;
    d3.select("#slice_slider_selection").text(selected_date());
    return chart_area.selectAll("path").data(pie_layout(pie_data)).attr("d", pie_arc);
  };

  pie_data_from_series = function(series_data) {
    var data;
    return data = series_data.map(function(d) {
      return {
        vals: d[freq].data,
        s_name: d.display_name
      };
    });
  };

  window.pie_these_series = function(series_data) {
    pie_data = pie_data_from_series(series_data);
    chart_area.selectAll("path").remove();
    return chart_area.selectAll("path").data(pie_layout(pie_data)).enter().append("path").attr("d", pie_arc).attr("fill", function(d) {
      return color(d.data.s_name);
    }).attr("stroke", "white").attr("stroke-width", 2).on("mouseover", function(d, i) {
      var slice;
      slice = d3.select(this);
      slice.attr("fill-opacity", ".3");
      return chart_area.append("text").attr("class", "pie_label").attr("text-anchor", "middle").attr("transform", "translate( " + (pie_arc.centroid(d)) + " )").text(d.data.s_name);
    }).on("mouseout", function(d) {
      var slice;
      slice = d3.select(this);
      slice.attr("fill-opacity", "1");
      return chart_area.select("text.pie_label").remove();
    });
  };

  window.visitor_pie_chart = function(container) {
    var center_x, center_y;
    slider_extent = [0, all_dates().length - 1];
    svg = set_up_svg(container);
    center_x = svg.attr("width") / 2;
    center_y = svg.attr("height") / 2;
    chart_area = svg.append("g").attr("id", "pie_chart_area").attr("transform", "translate(" + center_x + "," + center_y + ")");
    return svg.append("text").attr("id", "slice_slider_selection").attr("text-anchor", "middle").attr("x", center_x).attr("y", svg.attr("height") - 10).text("2013");
  };

}).call(this);
