(function() {
  var chart_extent, combine_extent, dummy_path, end_date, redraw_line_chart, start_date, time_axis, toggle_axis_button, trim_d, update_domain, update_x_domain, update_y_domain_with_new, x, x_from_slider, y, y_left, y_right;

  start_date = 2004;

  end_date = 2013;

  x_from_slider = function(d, i) {
    var dates, pos, slider_start;
    slider_start = $("#line_chart_slider_div").slider("option", "values")[0];
    dates = d3.select("#line_chart_slider_div").datum();
    pos = slider_start + i;
    return x(dates[pos]);
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

  time_axis = d3.svg.axis().scale(x);

  dummy_path = d3.svg.line().x(x_from_slider).y(0).defined(function(d) {
    return d !== null;
  });

  chart_extent = function(array) {
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

  trim_d = function(d, extent) {
    var dates;
    d.trimmed_data = d.data.slice(extent[0], extent[1] + 1);
    dates = d3.select("#line_chart_slider_div").datum();
    console.log("se:" + (dates.slice(extent[0], extent[1] + 1)));
    return console.log("do:" + (x.domain()));
  };

  update_x_domain = function(extent, duration) {
    var dates;
    if (duration == null) {
      duration = 0;
    }
    dates = d3.select("#line_chart_slider_div").datum();
    x.domain(dates.slice(extent[0], extent[1] + 1));
    return d3.select("#time_axis").transition().duration(duration).call(time_axis);
  };

  update_domain = function(axis, duration) {
    var all_data, data, series, _i, _len;
    if (duration == null) {
      duration = 500;
    }
    data = d3.select("g#chart_area").selectAll("." + y[axis]["class"]).data().map(function(d) {
      return d[freq].trimmed_data;
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

  redraw_line_chart = function(extent, duration) {
    var paths;
    if (duration == null) {
      duration = 0;
    }
    update_x_domain(extent);
    return paths = d3.select("g#chart_area").selectAll("path").attr("d", function(d) {
      trim_d(d[freq], extent);
      return y["left"].path(d[freq].trimmed_data);
    });
  };

  window.trim_time_series = function(event, ui) {
    var values;
    values = $("#line_chart_slider_div").slider("option", "values");
    return redraw_line_chart(values);
  };

  window.add_to_line_chart = function(d, axis) {
    var domain, duration, extent;
    duration = 500;
    extent = $("#line_chart_slider_div").slider("option", "values");
    trim_d(d[freq], extent);
    domain = chart_extent(d[freq].trimmed_data);
    update_y_domain_with_new(axis, domain, duration);
    d3.select("g#chart_area").append("path").datum(d).attr("id", y[axis]["class"] + ("_" + (series_to_class(d.udaman_name)))).attr("class", "" + y[axis]["class"] + " line_chart_path").attr("stroke", "#777").attr("d", function(d) {
      return dummy_path(d[freq].trimmed_data);
    });
    d3.select("g#chart_area").selectAll("path." + y[axis]["class"]).transition().duration(duration).attr("d", function(d) {
      return y[axis].path(d[freq].trimmed_data);
    });
    return toggle_axis_button(d.udaman_name, axis);
  };

  window.remove_from_line_chart = function(d, axis) {
    var chart_area, duration;
    duration = 500;
    chart_area = d3.select("g#chart_area");
    d3.select("#s_" + axis + "_" + (series_to_class(d.udaman_name))).remove();
    update_domain(axis, duration);
    chart_area.selectAll("path." + y[axis]["class"]).transition().duration(duration).attr("d", function(d) {
      return y[axis].path(d[freq].trimmed_data);
    });
    return toggle_axis_button(d.udaman_name, axis);
  };

  window.line_chart = function(container) {
    var chart_area, chart_area_height, chart_area_width, extent, margin, svg;
    svg = set_up_svg(container);
    margin = {
      top: 10,
      bottom: 25,
      left: 50,
      right: 50
    };
    chart_area_width = svg.attr("width") - margin.left - margin.right;
    chart_area_height = svg.attr("height") - margin.top - margin.bottom;
    extent = $("#line_chart_slider_div").slider("option", "values");
    update_x_domain(extent);
    x.rangePoints([0, chart_area_width]);
    y.left.scale.range([chart_area_height, 0]);
    y.right.scale.range([chart_area_height, 0]);
    svg.append("g").attr("id", "time_axis").attr("transform", "translate(" + margin.left + "," + (margin.top + chart_area_height) + ")").call(time_axis);
    svg.append("g").attr("id", "left_axis").attr("transform", "translate(" + margin.left + "," + margin.top + ")").call(y.left.axis);
    svg.append("g").attr("id", "right_axis").attr("transform", "translate(" + (margin.left + chart_area_width) + "," + margin.top + ")").call(y.right.axis);
    return chart_area = svg.append("g").attr("id", "chart_area").attr("transform", "translate(" + margin.left + "," + margin.top + ")");
  };

}).call(this);
