(function() {
  var all_dates, chart_area, color, dates_extent, get_common_dates, get_data_index_extent, mouseout_pie, mouseover_pie, pie_arc, pie_layout, selected_date, selected_pos, set_date_shown, set_slider_dates, slider_dates, slider_extent, svg;

  slider_extent = null;

  svg = null;

  chart_area = null;

  color = d3.scale.category20c();

  pie_layout = d3.layout.pie().value(function(d) {
    return d[freq].data[selected_pos()];
  });

  pie_arc = d3.svg.arc().outerRadius(100).innerRadius(0);

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

  set_date_shown = function() {
    return d3.select("#slice_slider_selection").text(selected_date());
  };

  window.redraw_slice = function(event, ui) {
    var pie_data, pie_slices;
    slider_extent = ui.values;
    set_date_shown();
    pie_slices = chart_area.selectAll("path");
    pie_data = pie_slices.data().map(function(d) {
      return d.data;
    });
    return pie_slices.data(pie_layout(pie_data), function(d) {
      return d.data.display_name;
    }).attr("d", pie_arc);
  };

  get_data_index_extent = function(data) {
    var end_i, start_i;
    start_i = data.findIndex(function(d) {
      return d !== null;
    });
    end_i = data.length - 1 - data.slice().reverse().findIndex(function(d) {
      return d !== null;
    });
    return [start_i, end_i];
  };

  get_common_dates = function(series_data) {
    var arr;
    arr = series_data.map(function(series) {
      return get_data_index_extent(series[freq].data);
    });
    return [
      d3.max(arr.map(function(d) {
        return d[0];
      })), d3.min(arr.map(function(d) {
        return d[1];
      }))
    ];
  };

  mouseover_pie = function(d, i) {
    var slice;
    slice = d3.select(this);
    slice.attr("fill-opacity", ".3");
    return chart_area.append("text").attr("class", "pie_label").attr("text-anchor", "middle").attr("transform", "translate( " + (pie_arc.centroid(d)) + " )").text(d.data.display_name);
  };

  mouseout_pie = function(d) {
    var slice;
    slice = d3.select(this);
    slice.attr("fill-opacity", "1");
    return chart_area.select("text.pie_label").remove();
  };

  set_slider_dates = function(extent) {
    slider_extent = extent;
    $("#time_slice_slider_div").slider("option", "min", extent[0]);
    $("#time_slice_slider_div").slider("option", "max", extent[1]);
    return set_date_shown();
  };

  window.pie_these_series = function(series_data) {
    var data_extent;
    data_extent = get_common_dates(series_data);
    set_slider_dates(data_extent);
    chart_area.selectAll("path").remove();
    return chart_area.selectAll("path").data(pie_layout(series_data), function(d) {
      return d.data.display_name;
    }).enter().append("path").attr("d", pie_arc).attr("fill", function(d) {
      return color(d.data.display_name);
    }).attr("stroke", "white").attr("stroke-width", 2).on("mouseover", mouseover_pie).on("mouseout", mouseout_pie);
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
