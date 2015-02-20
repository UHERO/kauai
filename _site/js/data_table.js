(function() {
  var add_parent, add_series, all_dates, cell_width, class_name_from_series_node, clear_series, click_cat, click_expander, click_series, create_axis_control, create_axis_controls, create_data_columns, create_series_label, create_series_rows, create_sparklines, create_ytd_column, datatable_width, draw_spark_area, draw_spark_path, draw_sparklines, flatten, flatten_children, mouseout_series, mouseover_series, populate_dates, s_row, selected_data, selected_dates, series_height, series_row_class, set_primary_series, slider_val, spark_area_path, spark_line, trimmed_data_object, update_data_columns, x, y;

  cell_width = 50;

  series_height = 50;

  datatable_width = 300;

  x = d3.scale.linear().clamp(true).range([0, 145]);

  y = d3.scale.linear().range([series_height - 10, 5]);

  window.mode = "line_bar";

  slider_val = null;

  all_dates = function() {
    return d3.select("#time_slice_slider_div").datum();
  };

  selected_dates = function() {
    return all_dates().slice(slider_val - 4, +slider_val + 1 || 9e9);
  };

  selected_data = function(d) {
    var yoy;
    yoy = d[freq].yoy.slice(slider_val - 4, +slider_val + 1 || 9e9);
    return d[freq].data.slice(slider_val - 4, +slider_val + 1 || 9e9).map(function(d, i) {
      return {
        data: d,
        yoy: yoy[i]
      };
    });
  };

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
    cat.attr("state", "collapsed");
    return d3.select(cat.node().parentNode).selectAll("div.series").transition().style("height", "0px");
  };

  window.expand = function(cat) {
    cat.attr("state", "expanded");
    return d3.select(cat.node().parentNode).selectAll("div.series").filter(function(d) {
      var child, collapsed, row;
      row = d3.select(this);
      collapsed = row.attr("state") === "collapsed";
      child = row.classed("child");
      return !child || !collapsed;
    }).transition().style("height", series_height + "px");
  };

  class_name_from_series_node = function(node) {
    return window.series_to_class(node.datum().udaman_name);
  };

  window.collapse_series = function(series) {
    series.attr("state", "collapsed");
    return d3.selectAll(".child_of_" + (class_name_from_series_node(series))).transition().style("height", "0px").style("border", "0px").attr("state", "collapsed");
  };

  window.expand_series = function(series) {
    series.attr("state", "expanded");
    return d3.selectAll(".child_of_" + (class_name_from_series_node(series))).transition().style("height", series_height + "px").attr("state", "expanded");
  };

  s_row = function(udaman_name) {
    return d3.select("#s_row_" + (window.series_to_class(udaman_name)));
  };

  click_cat = function(d) {
    var cat;
    cat = d3.select(this);
    if (cat.attr("state") === "expanded") {
      cat.select(".glyphicon").classed({
        "glyphicon-minus": false,
        "glyphicon-plus": true
      });
      return collapse(cat);
    } else {
      cat.select(".glyphicon").classed({
        "glyphicon-minus": true,
        "glyphicon-plus": false
      });
      return expand(cat);
    }
  };

  click_series = function(d) {
    var series;
    series = d3.select(this);
    return set_primary_series(series);
  };

  click_expander = function(d) {
    var series;
    series = s_row(d.udman_name);
    if (series.attr("state") === "expanded") {
      return collapse_series(series);
    } else {
      return expand_series(series);
    }
  };

  mouseover_series = function(d) {
    return d3.select(this).classed("hovered", true);
  };

  mouseout_series = function(d) {
    return d3.selectAll(".series").classed("hovered", false);
  };

  window.highlight_series_row = function(d) {
    return s_row(d.udaman_name).classed("selected", true);
  };

  window.unhighlight_series_row = function(d) {
    return s_row(d.udaman_name).classed("selected", false);
  };


  /*
   * this function replaces add_series and clear_series
   * the new functionality allows the user to
   * select the series on the left by clicking the series
   * a separate button will allow them to select 
   * at most one series on the right axis
   */

  set_primary_series = function(series) {
    var array_length, first_value_index, new_series, old_series;
    new_series = series.datum();
    old_series = d3.select(".series.selected").datum();
    if (new_series.udaman_name !== old_series.udaman_name && !d3.select("g#chart_area #path_" + (window.series_to_class(new_series.udaman_name))).classed("s_right")) {
      if (window.mode === "line_bar") {
        unhighlight_series_row(old_series);
        highlight_series_row(new_series);
        first_value_index = 0;
        array_length = new_series[window.freq].data.length;
        while (first_value_index < array_length && (new_series[window.freq].data[first_value_index] == null)) {
          first_value_index++;
        }
        console.log(first_value_index);
        $("#line_chart_slider_div").val(first_value_index, array_length - 1);
        window.trim_sparklines();
        window.trim_time_series();
        window.update_ytd_column();
        clear_line_and_bar_chart(old_series);
        return display_line_and_bar_chart(new_series);
      } else {
        unhighlight_series_row(old_series);
        highlight_series_row(new_series);
        window.add_to_line_chart(new_series, "left");
        return window.clear_from_line_chart(old_series);
      }
    }
  };

  window.set_secondary_series = function(series) {
    var new_secondary_series, old_secondary_series, on_toggle, primary_series;
    window.secondary_series = series;
    new_secondary_series = series.datum();
    primary_series = d3.select(".series.selected").datum();
    if (new_secondary_series.udaman_name !== primary_series.udaman_name) {
      on_toggle = d3.select(".right_toggle.on").node();
      if (on_toggle != null) {
        old_secondary_series = d3.select(on_toggle.parentNode).datum();
        add_to_line_chart(new_secondary_series, "right");
        clear_from_line_chart(old_secondary_series);
        d3.select(on_toggle).classed({
          "off": true,
          "on": false,
          "glyphicon-unchecked": true,
          "glyphicon-check": false
        });
      } else {
        line_and_bar_to_multi_line(new_secondary_series);
      }
      return series.select(".right_toggle").classed({
        "off": false,
        "on": true,
        "glyphicon-unchecked": false,
        "glyphicon-check": true
      });
    }
  };

  window.remove_secondary_series = function(series) {
    var d;
    d = series.datum();
    return multi_line_to_line_and_bar(d);
  };

  add_series = function(series) {
    var current_selection, d, sel_count;
    d = series.datum();
    current_selection = d3.selectAll(".series.selected");
    sel_count = current_selection.data().length;
    highlight_series_row(d);
    switch (sel_count) {
      case 0:
        return display_line_and_bar_chart(d);
      case 1:
        return line_and_bar_to_multi_line(d);
      default:
        return add_to_line_chart(d, "left");
    }
  };

  clear_series = function(series) {
    var current_selection, d, sel_count;
    d = series.datum();
    current_selection = d3.selectAll(".series.selected");
    sel_count = current_selection.data().length;
    unhighlight_series_row(d);
    switch (sel_count) {
      case 1:
        return clear_line_and_bar_chart(d);
      case 2:
        return multi_line_to_line_and_bar(d);
      default:
        return clear_from_line_chart(d);
    }
  };

  add_parent = function(series_data, parent) {
    series_data.series_parent = parent;
    return series_data;
  };

  flatten_children = function(series_data) {
    var series, series_list, _i, _len, _ref;
    series_list = [];
    series_list.push(add_parent(series_data, ""));
    if (series_data.children != null) {
      _ref = series_data.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        series = _ref[_i];
        series_list.push(add_parent(series, series_data.udaman_name));
      }
    }
    return series_list;
  };

  flatten = function(series_list) {
    var new_list, series, _i, _len;
    new_list = [];
    for (_i = 0, _len = series_list.length; _i < _len; _i++) {
      series = series_list[_i];
      if (series[window.freq] !== false) {
        new_list = new_list.concat(flatten_children(series));
      }
    }
    return new_list;
  };

  trimmed_data_object = function(d, start_i, end_i) {
    var new_d;
    new_d = jQuery.extend(true, {}, d);
    new_d.spark_data = d.data.slice(start_i, end_i + 1);
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

  window.trim_sparklines = function(event) {
    return draw_sparklines($("#line_chart_slider_div").val(), 0);
  };

  draw_sparklines = function(extent, duration) {
    var cat_series, dates, end_i, point, start_i, svg, trimmed_dates;
    cat_series = d3.selectAll("div.series");
    start_i = extent[0];
    end_i = extent[1];
    point = end_i - start_i;
    x.domain([0, end_i - start_i]);
    dates = d3.select("#line_chart_slider_div").datum();
    trimmed_dates = dates.slice(start_i, end_i + 1);
    svg = cat_series.select("svg").datum(function(d) {
      return trimmed_data_object(d[freq], start_i, end_i);
    });
    draw_spark_path(svg, duration);
    return draw_spark_area(svg, duration);
  };

  draw_spark_path = function(svg, duration) {
    var spark_path;
    spark_path = svg.selectAll("path.spark").data(function(d) {
      return [d.scaled_data];
    });
    spark_path.enter().append("path").attr("class", "spark").attr("stroke", "#03627f").attr("fill", "none");
    return spark_path.transition().duration(duration).attr("d", spark_line);
  };

  draw_spark_area = function(svg, duration) {
    var spark_area;
    spark_area = svg.selectAll("path.spark_area").data(function(d) {
      return [d.scaled_data];
    });
    spark_area.enter().append("path").attr("class", "spark_area").attr("stroke", "none").attr("fill", "#03627f").attr("fill-opacity", .1);
    return spark_area.transition().duration(duration).attr("d", spark_area_path);
  };

  window.slide_table = function(event, ui) {
    var offset, offset_val;
    slider_val = +$("#time_slice_slider_div").val();
    populate_dates();
    update_data_columns();
    offset_val = +$("#time_slice_slider_div").val() + 1;
    offset = -(offset_val * cell_width - datatable_width);
    return d3.selectAll(".container").style("margin-left", offset + "px");
  };

  populate_dates = function() {
    var data, dates;
    data = selected_dates();
    dates = d3.select("#datatable_header").selectAll(".header_cell").data(data);
    dates.enter().append("div").attr("class", "header_cell");
    dates.html(function(d) {
      return "" + d + "<br/><span class=\"pct_change\">%Chg</a>";
    });
    return dates.exit().remove();
  };

  create_ytd_column = function(cat_series) {
    var container;
    return container = cat_series.append("div").attr("class", "ytd_cell").html(function(d) {
      var last_date, last_obs, last_ytd_change, last_ytd_change_num, sign;
      last_obs = d[freq].last != null ? (+d[freq].last).toFixed(3) : "";
      last_date = d[freq].last != null ? d[freq].date[d[freq].last_i] : "";
      last_ytd_change_num = +d[freq].ytd_change[d[freq].last_i];
      last_ytd_change = last_ytd_change_num.toFixed(2) + "%";
      sign = last_ytd_change_num > 0 ? " pos" : " neg";
      return "<span class=\"last_obs\">" + last_obs + "</span><span class=\"last_date\">" + last_date + "</span><span class=\"ytd_change" + sign + "\">" + last_ytd_change + "</span>";
    });
  };

  window.update_ytd_column = function(event) {
    var last_index;
    last_index = ($("#line_chart_slider_div").val().map(function(value) {
      return +value;
    }))[1];
    return d3.selectAll(".ytd_cell").html(function(d) {
      var last_date, last_obs, last_ytd_change, sign;
      last_obs = d[freq].data[last_index] != null ? (+d[freq].data[last_index]).toFixed(3) : "";
      last_date = d[freq].data[last_index] != null ? d[freq].date[last_index] : "";
      if ((d[freq].data[last_index] == null) || isNaN(d[freq].ytd_change[last_index])) {
        last_ytd_change = "&nbsp;";
        sign = "";
      } else {
        last_ytd_change = (+d[freq].ytd_change[last_index]).toFixed(2) + "%";
        sign = +d[freq].ytd_change[last_index] > 0 ? " pos" : " neg";
      }
      return "<span class=\"last_obs\">" + last_obs + "</span><span class=\"last_date\">" + last_date + "</span><span class=\"ytd_change" + sign + "\">" + last_ytd_change + "</span>";
    });
  };

  create_data_columns = function(cat_series) {
    var container;
    container = cat_series.append("div").attr("class", "data_cols");
    return container.selectAll("div.cell").data(function(d) {
      return selected_data(d);
    }).enter().append("div").attr("class", "cell").html(function(d) {
      var data, sign, yoy;
      data = d.data != null ? (+d.data).toFixed(3) : "";
      yoy = d.yoy != null ? (+d.yoy).toFixed(2) + "%" : "";
      yoy = d.yoy > 0 ? "+" + yoy : yoy;
      sign = d.yoy > 0 ? " pos" : (d.yoy < 0 ? " neg" : "");
      return "<span class=\"cell_value\">" + data + "</span><span class=\"cell_yoy" + sign + "\">" + yoy + "</span>";
    });
  };

  update_data_columns = function() {
    var cat_series, cells, container;
    cat_series = d3.selectAll("div.series");
    container = cat_series.selectAll(".data_cols");
    cells = container.selectAll("div.cell").data(function(d) {
      return selected_data(d);
    });
    cells.enter().append("div").attr("class", "cell");
    return cells.html(function(d) {
      var data, sign, yoy;
      data = d.data != null ? (+d.data).toFixed(3) : "";
      yoy = d.yoy != null ? (+d.yoy).toFixed(2) + "%" : "";
      yoy = d.yoy > 0 ? "+" + yoy : yoy;
      sign = d.yoy > 0 ? " pos" : (d.yoy < 0 ? " neg" : "");
      return "<span class=\"cell_value\">" + data + "</span><span class=\"cell_yoy" + sign + "\">" + yoy + "</span>";
    });
  };

  create_axis_control = function(cat_series, axis) {
    return cat_series.append("span").attr("class", "" + axis + "_toggle off glyphicon glyphicon-unchecked").on("click", function(d) {
      var button;
      d3.event.stopPropagation();
      button = d3.select(this);
      if (button.classed("off")) {
        return set_secondary_series(d3.select(button.node().parentNode));
      } else {
        button.classed({
          "off": true,
          "on": false,
          "glyphicon-unchecked": true,
          "glyphicon-check": false
        });
        return remove_secondary_series(d3.select(button.node().parentNode));
      }
    });
  };

  create_axis_controls = function(cat_series) {
    return cat_series.call(create_axis_control, "right");
  };

  create_sparklines = function(cat_series) {
    var spark_paths, spark_range;
    spark_paths = cat_series.append("svg").attr("class", "sparkline").attr("height", series_height).attr("width", 150);
    spark_range = $("#line_chart_slider_div").val();
    return draw_sparklines(spark_range, 0);
  };

  create_series_label = function(cat_series) {
    var label;
    label = cat_series.append("div").attr("class", "series_label");
    label.append("span").text(function(d) {
      return d.display_name;
    });
    label.append("br");
    return label.append("span").text(function(d) {
      return "(" + d.units + ")";
    });
  };

  series_row_class = function(d) {
    var child_class, parent_class;
    child_class = d.series_parent !== "" ? " child child_of_" + (window.series_to_class(d.series_parent)) : "";
    parent_class = d.children_sum ? " parent" : "";
    return "series" + child_class + parent_class;
  };

  create_series_rows = function(cat_divs) {
    var cat_series;
    cat_series = cat_divs.selectAll("div.series").data(function(d) {
      return flatten(d.series_list);
    }).enter().append("div").attr("id", function(d) {
      return "s_row_" + (window.series_to_class(d.udaman_name));
    }).attr("class", series_row_class).attr("state", "expanded").style("height", series_height + "px").style("cursor", "pointer").on("mouseover", mouseover_series).on("mouseout", mouseout_series).on("click", click_series);
    return cat_series.call(create_series_label).call(create_sparklines).call(create_axis_controls).call(create_ytd_column).call(create_data_columns);
  };

  window.create_data_table = function(page_data) {
    var cat_divs, cat_labels;
    slider_val = all_dates().length - 1;
    populate_dates();
    cat_divs = d3.select("#series_display").selectAll("div.category").data(page_data.series_groups).enter().append("div").attr("class", "category");
    cat_labels = cat_divs.append("div").attr("class", "cat_label").attr("id", function(d) {
      return "cat_" + (window.series_to_class(d.group_name));
    }).attr("state", "expanded").html(function(d) {
      return "<span class='glyphicon glyphicon-minus'></span> " + (d.group_name.replace('Total ', ''));
    }).on("mouseover", function(d) {
      return d3.select(this).style("background-color", "#ecffc7");
    }).on("mouseout", function(d) {
      return d3.selectAll('.cat_label').style("background-color", "#FFF");
    }).on("click", click_cat);
    return create_series_rows(cat_divs);
  };

}).call(this);
