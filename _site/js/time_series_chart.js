(function() {
  var all_dates, chart_extent, combine_extent, dates_extent, dummy_path, hide_bars, redraw_line_and_bar_chart, redraw_line_chart, regenerate_bars, regenerate_path, s_path, show_bars, slider_dates, slider_extent, time_axis, toggle_axis_button, trim_d, trim_yoy, update_domain, update_x_domain, update_y_domain_with_new, x, x_from_slider, y, y_height, y_left, y_right, y_yoy, yoy_chart_extent;

  slider_extent = null;

  x_from_slider = function(d, i) {
    return x(all_dates()[slider_extent[0] + i]);
  };

  y_left = d3.scale.linear();

  y_right = d3.scale.linear();

  x = d3.scale.ordinal();

  window.x_scale = x;

  y = {
    left: {
      "class": "s_left",
      scale: y_left,
      axis: d3.svg.axis().scale(y_left).orient("left"),
      path: d3.svg.line().x(x_from_slider).y(function(d) {
        return y_left(d);
      }).defined(function(d) {
        return d !== null;
      })
    },
    right: {
      "class": "s_right",
      scale: y_right,
      axis: d3.svg.axis().scale(y_right).orient("right"),
      path: d3.svg.line().x(x_from_slider).y(function(d) {
        return y_right(d);
      }).defined(function(d) {
        return d !== null;
      })
    }
  };

  time_axis = d3.svg.axis().scale(x).tickFormat(function(d, i) {
    if (i === 0 || i === (slider_extent[1] - slider_extent[0])) {
      return d;
    } else {
      return "";
    }
  });

  dummy_path = d3.svg.line().x(x_from_slider).y(-20).defined(function(d) {
    return d !== null;
  });

  y_yoy = function(d) {
    if (d < 0) {
      return y_right(0);
    } else {
      return y_right(d);
    }
  };

  y_height = function(d) {
    return Math.abs(y_right(0) - y_right(d));
  };

  all_dates = function() {
    return d3.select("#line_chart_slider_div").datum();
  };

  dates_extent = function(extent) {
    return all_dates().slice(extent[0], extent[1] + 1);
  };

  slider_dates = function() {
    var extent;
    extent = slider_extent;
    return dates_extent(extent);
  };

  chart_extent = function(array) {
    var full_extent, range;
    full_extent = d3.extent(array);
    range = full_extent[1] - full_extent[0];
    return [full_extent[0] - range * .1, full_extent[1] + range * .1];
  };

  yoy_chart_extent = function(array) {
    var full_extent, range;
    full_extent = d3.extent(array);
    range = full_extent[1] - full_extent[0];
    return [full_extent[0] - range * .1, full_extent[1] + range * .1];
  };

  combine_extent = function(ex1, ex2) {
    return [d3.min([ex1[0], ex2[0]]), d3.max([ex1[1], ex2[1]])];
  };

  toggle_axis_button = function(series, axis) {
    var button;
    button = d3.select("#s_row_" + (series_to_class(series)) + " ." + axis + "_toggle");
    if (button.classed("off")) {
      return button.text("-").attr("class", "" + axis + "_toggle on");
    } else {
      return button.text("+").attr("class", "" + axis + "_toggle off");
    }
  };

  s_path = function(udaman_name) {
    return d3.select("g#chart_area #path_" + (series_to_class(udaman_name)));
  };

  trim_d = function(d, extent) {
    return d.trimmed_data = d.data.slice(extent[0], extent[1] + 1);
  };

  trim_yoy = function(d, extent) {
    return d.trimmed_yoy = d.yoy.slice(extent[0], extent[1] + 1);
  };

  update_x_domain = function(extent, duration) {
    if (duration == null) {
      duration = 0;
    }
    return x.domain(dates_extent(extent));
  };

  update_domain = function(axis, duration) {
    var all_data, data, series, _i, _len;
    if (duration == null) {
      duration = 500;
    }
    data = d3.select("g#chart_area").selectAll("." + y[axis]["class"]).data().map(function(d) {
      return d[freq].data;
    });
    if (data.length === 0) {
      y[axis].scale.domain([0, 1]);
    } else {
      all_data = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        series = data[_i];
        all_data = all_data.concat(series);
      }
      y[axis].scale.domain(chart_extent(all_data));
    }
    return d3.select("#" + axis + "_axis").transition().duration(duration).call(y[axis].axis);
  };

  update_y_domain_with_new = function(axis, domain, duration) {
    var cur_domain;
    if (duration == null) {
      duration = 500;
    }
    cur_domain = y[axis].scale.domain();
    if (!d3.select("g#chart_area").selectAll("path." + y[axis]["class"]).empty()) {
      domain = combine_extent(cur_domain, domain);
    }
    y[axis].scale.domain(domain).nice();
    return d3.select("#" + axis + "_axis").transition().duration(duration).call(y[axis].axis);
  };

  regenerate_path = function(d, extent, axis) {
    trim_d(d[freq], extent);
    return y[axis].path(d[freq].trimmed_data);
  };

  show_bars = function(d, extent) {
    var bars, duration;
    duration = 500;
    trim_yoy(d[freq], extent);
    bars = d3.select("g#chart_area").selectAll("rect.yoy").data(d[freq].trimmed_yoy);
    bars.enter().append("rect").attr("class", "yoy").attr("fill", "gray").attr("fill-opacity", 0.5).attr("y", y_right(0)).attr("x", x_from_slider).attr("height", 0).attr("width", 1);
    return bars.transition().duration(duration).attr("y", y_yoy).attr("height", y_height);
  };

  regenerate_bars = function(d, extent) {
    var bars;
    trim_yoy(d[freq], extent);
    bars = d3.select("g#chart_area").selectAll("rect.yoy").data(d[freq].trimmed_yoy);
    bars.enter().append("rect").attr("class", "yoy").attr("fill", "gray").attr("fill-opacity", 0.5);
    bars.exit().remove();
    return bars.attr("x", x_from_slider).attr("y", y_yoy).attr("width", 1).attr("height", y_height);
  };

  hide_bars = function() {
    var bars, duration;
    duration = 500;
    bars = d3.select("g#chart_area").selectAll("rect.yoy").transition().duration(duration).attr("y", y_right(0)).attr("height", 0);
    y["right"].scale.domain([0, 1]);
    return d3.select("#right_axis").transition().duration(duration).call(y["right"].axis);
  };

  redraw_line_and_bar_chart = function(extent) {
    var path;
    update_x_domain(extent);
    path = d3.select("g#chart_area path.with_bar").attr("d", function(d) {
      return regenerate_path(d, extent, "left");
    });
    return regenerate_bars(path.datum(), extent);
  };

  redraw_line_chart = function(extent, duration) {
    var l_paths, r_paths;
    if (duration == null) {
      duration = 0;
    }
    update_x_domain(extent);
    l_paths = d3.selectAll("g#chart_area path.s_left").attr("d", function(d) {
      return regenerate_path(d, extent, "left");
    });
    return r_paths = d3.selectAll("g#chart_area path.s_right").attr("d", function(d) {
      return regenerate_path(d, extent, "right");
    });
  };

  window.trim_time_series = function(event, ui) {
    var text;
    slider_extent = ui.values;
    d3.select("h3#date_line_left").text(all_dates()[ui.values[0]]);
    d3.select("h3#date_line_right").text(all_dates()[ui.values[1]]);
    if (d3.select("#line_chart_slider_container a.ui-state-focus").attr("slider") === "left") {
      text = d3.select("#line_chart_slider_container a.ui-state-focus").style("left").split("px");
      console.log(text);
      d3.select("h3#date_line_left").style("left", (parseInt(text[0]) + 480) + "px");
    }
    if (d3.select("#line_chart_slider_container a.ui-state-focus").attr("slider") === "right") {
      text = d3.select("#line_chart_slider_container a.ui-state-focus").style("left").split("px");
      d3.select("h3#date_line_right").style("left", (parseInt(text[0]) + 480) + "px");
    }
    switch (window.mode) {
      case "multi_line":
        return redraw_line_chart(slider_extent);
      case "line_bar":
        return redraw_line_and_bar_chart(slider_extent);
      default:
        return redraw_line_chart(slider_extent);
    }
  };

  window.line_and_bar_to_multi_line = function(d) {
    hide_bars();
    d3.select("g#chart_area path.with_bar").classed("with_bar", false).classed("s_left", true);
    add_to_line_chart(d, "left");
    return window.mode = "multi_line";
  };

  window.multi_line_to_line_and_bar = function(d) {
    var duration, keep_path, kp_d, yoy_domain;
    duration = 500;
    clear_from_line_chart(d);
    keep_path = d3.select("g#chart_area path.s_left, g#chart_area path.s_right").classed("with_bar", true);
    kp_d = keep_path.datum();
    yoy_domain = yoy_chart_extent(kp_d[freq].yoy);
    update_y_domain_with_new("right", yoy_domain, duration);
    show_bars(kp_d, slider_extent);
    return window.mode = "line_bar";
  };

  window.clear_from_line_chart = function(d) {
    var axis, path;
    path = s_path(d.udaman_name);
    axis = path.classed("s_left") ? "left" : "right";
    return remove_from_line_chart(d, axis);
  };

  window.clear_line_and_bar_chart = function(d) {
    hide_bars();
    return remove_from_line_chart(d, "left");
  };

  window.display_line_and_bar_chart = function(d) {
    var domain, duration, path, yoy_domain;
    highlight_series_row(d);
    duration = 500;
    trim_d(d[freq], slider_extent);
    domain = chart_extent(d[freq].data);
    yoy_domain = yoy_chart_extent(d[freq].yoy);
    path = d3.select("g#chart_area #path_" + (series_to_class(d.udaman_name)));
    update_y_domain_with_new("left", domain, duration);
    update_y_domain_with_new("right", yoy_domain, duration);
    path.classed("with_bar", true).attr("d", function(d) {
      return dummy_path(d[freq].trimmed_data);
    });
    path.transition().duration(duration).attr("d", function(d) {
      return y["left"].path(d[freq].trimmed_data);
    });
    return show_bars(d, slider_extent);
  };

  window.add_to_line_chart = function(d, axis) {
    var domain, duration, path;
    duration = 500;
    trim_d(d[freq], slider_extent);
    domain = chart_extent(d[freq].data);
    path = d3.select("g#chart_area #path_" + (series_to_class(d.udaman_name)));
    update_y_domain_with_new(axis, domain, duration);
    path.classed("" + y[axis]["class"], true).attr("d", function(d) {
      return dummy_path(d[freq].trimmed_data);
    });
    d3.selectAll("g#chart_area path." + y[axis]["class"]).transition().duration(duration).attr("d", function(d) {
      return y[axis].path(d[freq].trimmed_data);
    });
    return toggle_axis_button(d.udaman_name, axis);
  };

  window.remove_from_line_chart = function(d, axis) {
    var chart_area, duration, path;
    duration = 500;
    chart_area = d3.select("g#chart_area");
    path = d3.select("g#chart_area #path_" + (series_to_class(d.udaman_name)));
    path.classed("s_" + axis, false);
    path.transition().duration(500).attr("d", function(d) {
      return dummy_path(d[freq].trimmed_data);
    });
    update_domain(axis, duration);
    chart_area.selectAll("path." + y[axis]["class"]).transition().duration(duration).attr("d", function(d) {
      return y[axis].path(d[freq].trimmed_data);
    });
    return toggle_axis_button(d.udaman_name, axis);
  };

  window.set_up_line_chart_paths = function(data) {
    return d3.select("g#chart_area").selectAll("path.line_chart_path").data(data).enter().append("path").attr("id", function(d) {
      return "path_" + (series_to_class(d.udaman_name));
    }).attr("class", function(d) {
      return "" + (series_to_class(d.udaman_name)) + " line_chart_path";
    }).attr("stroke", "#777");
  };

  window.line_chart = function(container) {
    var chart_area, chart_area_height, chart_area_width, margin, svg;
    svg = set_up_svg(container);
    margin = {
      top: 10,
      bottom: 20,
      left: 50,
      right: 50
    };
    chart_area_width = svg.attr("width") - margin.left - margin.right;
    chart_area_height = svg.attr("height") - margin.top - margin.bottom;
    slider_extent = [0, all_dates().length - 1];
    update_x_domain(slider_extent);
    x.rangePoints([0, chart_area_width]);
    y.left.scale.range([chart_area_height, 0]);
    y.right.scale.range([chart_area_height, 0]);
    svg.append("g").attr("id", "left_axis").attr("transform", "translate(" + margin.left + "," + margin.top + ")").call(y.left.axis);
    svg.append("g").attr("id", "right_axis").attr("transform", "translate(" + (margin.left + chart_area_width) + "," + margin.top + ")").call(y.right.axis);
    return chart_area = svg.append("g").attr("id", "chart_area").attr("transform", "translate(" + margin.left + "," + margin.top + ")");
  };

}).call(this);
