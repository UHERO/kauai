(function() {
  var all_dates, chart_area, color, dates_extent, get_common_dates, get_data_index_extent, max_pie, mouseout_pie, mouseover_pie, pie_arc, pie_layout, selected_date, set_date_shown, set_slider_dates, set_up_pie_chart_title, slider_val, svg;

  slider_val = null;

  svg = null;

  chart_area = null;

  max_pie = null;

  color = d3.scale.category20c();

  pie_layout = d3.layout.pie().value(function(d) {
    return d[freq].data[slider_val];
  });

  pie_arc = d3.svg.arc().outerRadius(100).innerRadius(0);

  all_dates = function() {
    return d3.select("#time_slice_slider_div").datum();
  };

  dates_extent = function(extent) {
    return all_dates().slice(extent[0], extent[1] + 1);
  };

  selected_date = function() {
    return all_dates()[slider_val];
  };

  set_date_shown = function() {
    return d3.select("#slice_slider_selection").text(selected_date());
  };

  window.redraw_slice = function(event, ui) {
    var pie_data, pie_slices;
    slider_val = ui.value;
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
    chart_area.append("text").attr("class", "pie_label").attr("text-anchor", "middle").attr("transform", "translate( " + (pie_arc.centroid(d)) + " )").text(d.data.display_name);
    if (max_pie.value === d.value) {
      return chart_area.select("text.in_pie_label").remove();
    }
  };

  mouseout_pie = function(d) {
    var slice;
    slice = d3.select(this);
    slice.attr("fill-opacity", "1");
    chart_area.select("text.pie_label").remove();
    if (max_pie.value === d.value) {
      return chart_area.selectAll("text").data([max_pie]).enter().append("text").attr("class", "in_pie_label").attr("text-anchor", "middle").attr("transform", function(d) {
        return "translate( " + (pie_arc.centroid(d)) + " )";
      }).text(function(d) {
        return d.data.display_name;
      }).style("font-size", "9px").style('font-weight', "bold");
    }
  };

  set_slider_dates = function(extent) {
    slider_val = extent[1];
    $("#time_slice_slider_div").slider("option", "min", extent[0]);
    $("#time_slice_slider_div").slider("option", "max", extent[1]);
    return set_date_shown();
  };

  set_up_pie_chart_title = function(container) {
<<<<<<< HEAD
    return container.selectAll("div#links").data(["Visitor Arrivals", "Visitor Spending"]).enter().append("a").attr("class", "pie_chart_title").attr("id", function(d) {
      return d.replace(" ", "_");
    }).text(function(d) {
      return d;
    }).on("click", function(d) {
      d3.selectAll(".pie_chart_title").style("font-weight", "normal");
      return d3.select(this).style("font-weight", "bold");
=======
    return container.selectAll("a").data(["Visitor Arrivals", "Visitor Spending"]).enter().append("a").attr("class", "pie_chart_title").attr("id", function(d) {
      return d.replace(" ", "_");
    }).html(function(d) {
      if (d === "Visitor Arrivals") {
        return d + "&nbsp" + "&#124" + "&nbsp";
      } else {
        return d + "&nbsp";
      }
>>>>>>> d03c16dd8e4be6f925ea7cd7eae4bb483478ebf4
    });
  };

  window.pie_these_series = function(series_data) {
    var data_extent, sorted_array;
    data_extent = get_common_dates(series_data);
    set_slider_dates(data_extent);
    chart_area.selectAll("path").remove();
    sorted_array = pie_layout(series_data).sort(function(a, b) {
      return a.value - b.value;
    });
    console.log(sorted_array);
    max_pie = sorted_array[sorted_array.length - 1];
    chart_area.selectAll("path").data(pie_layout(series_data), function(d) {
      return d.data.display_name;
    }).enter().append("path").attr("d", pie_arc).attr("fill", function(d) {
      return color(d.data.display_name);
    }).attr("stroke", "white").attr("stroke-width", 2).on("mouseover", mouseover_pie).on("mouseout", mouseout_pie);
    return chart_area.selectAll("text").data([max_pie]).enter().append("text").attr("class", "in_pie_label").attr("text-anchor", "middle").attr("transform", function(d) {
      return "translate( " + (pie_arc.centroid(d)) + " )";
    }).text(function(d) {
      return d.data.display_name;
    }).style("font-size", "9px").style('font-weight', "bold");
  };

  window.visitor_pie_chart = function(container) {
    var center_x, center_y;
    set_up_pie_chart_title(container);
    slider_val = all_dates().length - 1;
    svg = set_up_svg(container);
    center_x = svg.attr("width") / 2;
    center_y = svg.attr("height") / 2;
    chart_area = svg.append("g").attr("id", "pie_chart_area").attr("transform", "translate(" + center_x + "," + center_y + ")");
    return svg.append("text").attr("id", "slice_slider_selection").attr("text-anchor", "middle").attr("x", center_x).attr("y", svg.attr("height") - 10).text("2013");
  };

}).call(this);
