(function() {
  var create_axis_control, create_axis_controls, create_series_label, create_series_rows, create_sparklines, draw_spark_area, draw_spark_path, draw_sparklines, mouseout_series, mouseover_series, series_height, set_slider_in_div, spark_area_path, spark_line, trim_sparklines, trimmed_data_object, x, y;

  series_height = 45;

  x = d3.scale.linear().clamp(true).range([0, 145]);

  y = d3.scale.linear().range([series_height, 5]);

  spark_line = d3.svg.line().x(function(d, i) {
    return x(i);
  }).y(function(d) {
    return d;
  }).defined(function(d) {
    return d !== null;
  });

  spark_area_path = d3.svg.area().x(function(d, i) {
    return x(i);
  }).y1(function(d) {
    return d;
  }).y0(series_height).defined(function(d) {
    return d !== null;
  });

  window.collapse = function(cat) {
    cat.transition().style("height", series_height + "px").style("line-height", series_height + "px").attr("state", "collapsed");
    return d3.select(cat.node().parentNode).selectAll("div.series").transition().style("height", function(d) {
      if (d.primary === "Primary") {
        return series_height + "px";
      } else {
        return "0px";
      }
    });
  };

  window.expand = function(cat) {
    cat.transition().style("height", function(d) {
      return (d.value.length * series_height) + "px";
    }).style("line-height", function(d) {
      return (d.value.length * series_height) + "px";
    }).attr("state", "expanded");
    return d3.select(cat.node().parentNode).selectAll("div.series").transition().style("height", series_height + "px");
  };

  window.create_data_table = function() {
    var cat_divs, cat_labels;
    cat_divs = d3.select("#series_display").selectAll("div.category").data(d3.entries(ts_by_category)).enter().append("div").attr("class", "category");
    cat_labels = cat_divs.append("div").attr("class", "cat_label").attr("id", function(d) {
      return "cat_" + d.key;
    }).attr("state", "expanded").text(function(d) {
      return d.key;
    }).style("height", function(d) {
      return (d.value.length * series_height) + "px";
    }).style("line-height", function(d) {
      return (d.value.length * series_height) + "px";
    }).on("mouseover", function(d) {
      return d3.select(this).style("background-color", "#999");
    }).on("mouseout", function(d) {
      return d3.selectAll(".cat_label").style("background-color", "#CCC");
    }).on("click", function(d) {
      var cat;
      cat = d3.select(this);
      if (cat.attr("state") === "expanded") {
        return collapse(cat);
      } else {
        return expand(cat);
      }
    });
    return create_series_rows(cat_divs);
  };

  mouseover_series = function(d) {
    var this_cat;
    return this_cat = d3.select(this).style("background-color", "#EEE");
  };

  mouseout_series = function(d) {
    return d3.selectAll(".series").style("background-color", "#FFF").selectAll("div");
  };

  create_series_rows = function(cat_divs) {
    var cat_series;
    cat_series = cat_divs.append("div").attr("class", "cat_series").selectAll("div.series").data(function(d) {
      return d.value;
    }).enter().append("div").attr("id", function(d) {
      return "s_row_" + (series_to_class(d.name));
    }).attr("class", "series").style("height", series_height + "px").on("mouseover", mouseover_series).on("mouseout", mouseout_series);
    return cat_series.call(create_series_label).call(create_sparklines).call(create_axis_controls);
  };

  create_series_label = function(cat_series) {
    return cat_series.append("div").attr("class", "series_label").style("line-height", series_height + "px").append("span").text(function(d) {
      return d.name;
    });
  };

  create_sparklines = function(cat_series) {
    var spark_paths;
    spark_paths = cat_series.append("svg").attr("class", "sparkline").attr("height", series_height).attr("width", 150);
    return draw_sparklines([0, all_dates.length - 1], 0);
  };

  create_axis_control = function(cat_series, axis) {
    return cat_series.append("div").attr("class", "" + axis + "_toggle off").text("+").on("click", function(d) {
      var button;
      button = d3.select(this);
      if (button.classed("off")) {
        return add_to_line_chart(d.name, axis);
      } else {
        return remove_from_line_chart(d.name, axis);
      }
    });
  };

  create_axis_controls = function(cat_series) {
    return cat_series.call(create_axis_control, "left").call(create_axis_control, "right");
  };

  draw_sparklines = function(extent, duration) {
    var cat_series, end_i, point, start_i, svg, trimmed_dates;
    cat_series = d3.selectAll("div.series");
    start_i = extent[0];
    end_i = extent[1];
    point = end_i - start_i;
    x.domain([0, end_i - start_i]);
    trimmed_dates = all_dates.slice(start_i, end_i + 1);
    d3.select("#sparkline_header").text(trimmed_dates[end_i - start_i]);
    svg = cat_series.select("svg").datum(function(d) {
      return trimmed_data_object(d, start_i, end_i);
    });
    draw_spark_path(svg, duration);
    return draw_spark_area(svg, duration);
  };

  draw_spark_path = function(svg, duration) {
    var spark_path;
    spark_path = svg.selectAll("path.spark").data(function(d) {
      return [d.scaled_data];
    });
    spark_path.enter().append("path").attr("class", "spark").attr("stroke", "#3182bd").attr("fill", "none");
    return spark_path.transition().duration(duration).attr("d", spark_line);
  };

  draw_spark_area = function(svg, duration) {
    var spark_area;
    spark_area = svg.selectAll("path.spark_area").data(function(d) {
      return [d.scaled_data];
    });
    spark_area.enter().append("path").attr("class", "spark_area").attr("stroke", "none").attr("fill", "#3182bd").attr("fill-opacity", .1);
    return spark_area.transition().duration(duration).attr("d", spark_area_path);
  };

  trimmed_data_object = function(d, start_i, end_i) {
    var new_d;
    new_d = jQuery.extend(true, {}, d);
    new_d.spark_data = d.spark_data.slice(start_i, end_i + 1);
    y.domain(d3.extent(new_d.spark_data));
    new_d.scaled_data = new_d.spark_data.map(function(e) {
      if (e === null) {
        return null;
      } else {
        return y(e);
      }
    });
    return new_d;
  };

  trim_sparklines = function(event, ui) {
    return draw_sparklines(ui.values, 0);
  };

  set_slider_in_div = function(div_id, val1, val2, slide_func) {
    d3.select("#" + div_id).remove();
    d3.select("#" + div_id.replace("div", "container")).insert("div", "div#buttons").attr("id", div_id).attr("class", "slider");
    return $("#" + div_id).slider({
      range: true,
      min: 0,
      max: all_dates.length - 1,
      values: [val1, val2],
      slide: slide_func
    });
  };

  window.set_up_sliders = function() {
    return set_slider_in_div("sparkline_slider_div", 0, all_dates.length - 1, trim_sparklines);
  };

}).call(this);
