(function() {
  var chart_extent, combine_extent, dummy_path, end_date, get_data_in_chart_view, get_series_extent, num, start_date, time_axis, toggle_axis_button, update_domain, x, y, y_left, y_right;

  start_date = 2004;

  end_date = 2013;

  y_left = d3.scale.linear();

  y_right = d3.scale.linear();

  x = d3.scale.ordinal().domain((function() {
    var _i, _results;
    _results = [];
    for (num = _i = start_date; start_date <= end_date ? _i <= end_date : _i >= end_date; num = start_date <= end_date ? ++_i : --_i) {
      _results.push(num);
    }
    return _results;
  })());

  y = {
    left: {
      "class": "s_left",
      scale: y_left,
      axis: d3.svg.axis().scale(y_left).orient("left"),
      path: d3.svg.line().x(function(d) {
        return x(+d.period);
      }).y(function(d) {
        return y_left(d.val);
      })
    },
    right: {
      "class": "s_right",
      scale: y_right,
      axis: d3.svg.axis().scale(y_right).orient("right"),
      path: d3.svg.line().x(function(d) {
        return x(+d.period);
      }).y(function(d) {
        return y_right(d.val);
      })
    }
  };

  time_axis = d3.svg.axis().scale(x);

  dummy_path = d3.svg.line().x(function(d, i) {
    return x(start_date + i);
  }).y(0);

  chart_extent = function(array) {
    var full_extent, range;
    full_extent = d3.extent(array);
    range = full_extent[1] - full_extent[0];
    return [full_extent[0] - range * .1, full_extent[1] + range * .1];
  };

  get_data_in_chart_view = function(series_name) {
    return ts_annual[series_name].data.filter(function(d) {
      return +d.period <= end_date && +d.period >= start_date;
    });
  };

  get_series_extent = function(series_data) {
    return chart_extent(series_data.map(function(d) {
      return +d.val;
    }));
  };

  combine_extent = function(ex1, ex2) {
    return [d3.min([ex1[0], ex2[0]]), d3.max([ex1[1], ex2[1]])];
  };

  update_domain = function(series_datas, scale) {
    var all_data, series, _i, _len;
    if (series_datas.length === 0) {
      return [0, 1];
    }
    all_data = [];
    for (_i = 0, _len = series_datas.length; _i < _len; _i++) {
      series = series_datas[_i];
      all_data = all_data.concat(series);
    }
    return scale.domain(get_series_extent(all_data));
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

  window.add_to_line_chart = function(series, axis) {
    var chart_area, cur_domain, data, domain, duration;
    duration = 500;
    chart_area = d3.select("g#chart_area");
    data = get_data_in_chart_view(series);
    domain = get_series_extent(data);
    cur_domain = y[axis].scale.domain();
    if (!chart_area.selectAll("path." + y[axis]["class"]).empty()) {
      domain = combine_extent(cur_domain, domain);
    }
    y[axis].scale.domain(domain).nice();
    d3.select("#" + axis + "_axis").transition().duration(duration).call(y[axis].axis);
    chart_area.append("path").datum(data).attr("id", y[axis]["class"] + ("_" + (series_to_class(series)))).attr("class", "" + y[axis]["class"] + " line_chart_path").attr("stroke", "#777").attr("d", dummy_path);
    chart_area.selectAll("path." + y[axis]["class"]).transition().duration(duration).attr("d", y[axis].path);
    return toggle_axis_button(series, axis);
  };

  window.remove_from_line_chart = function(series, axis) {
    var chart_area, duration;
    duration = 500;
    chart_area = d3.select("g#chart_area");
    d3.select("#s_" + axis + "_" + (series_to_class(series))).remove();
    update_domain(chart_area.selectAll("." + y[axis]["class"]).data(), y[axis].scale);
    d3.select("#" + axis + "_axis").transition().duration(duration).call(y[axis].axis);
    chart_area.selectAll("path." + y[axis]["class"]).transition().duration(duration).attr("d", y[axis].path);
    return toggle_axis_button(series, axis);
  };

  window.line_chart = function(container) {
    var chart_area, chart_area_height, chart_area_width, margin, svg;
    svg = set_up_svg(container);
    margin = {
      top: 10,
      bottom: 25,
      left: 50,
      right: 50
    };
    chart_area_width = svg.attr("width") - margin.left - margin.right;
    chart_area_height = svg.attr("height") - margin.top - margin.bottom;
    x.rangePoints([0, chart_area_width]);
    y.left.scale.range([chart_area_height, 0]);
    y.right.scale.range([chart_area_height, 0]);
    svg.append("g").attr("id", "time_axis").attr("transform", "translate(" + margin.left + "," + (margin.top + chart_area_height) + ")").call(time_axis);
    svg.append("g").attr("id", "left_axis").attr("transform", "translate(" + margin.left + "," + margin.top + ")").call(y.left.axis);
    svg.append("g").attr("id", "right_axis").attr("transform", "translate(" + (margin.left + chart_area_width) + "," + margin.top + ")").call(y.right.axis);
    return chart_area = svg.append("g").attr("id", "chart_area").attr("transform", "translate(" + margin.left + "," + margin.top + ")");
  };

}).call(this);
