(function() {
  var all_clustered_data, all_dates, chart_area, clustered_color, clustered_color3, dates_extent, get_common_dates, get_data_index_extent, max_pie, mouseout_pie, mouseover_pie, pie_arc, pie_layout, selected_data, selected_date, selected_dates, set_date_shown, set_slider_dates, slider_val, svg, treemap_mousemove, treemap_mouseout, treemap_position, treemap_props, uhero_color10, uhero_color5, x, x0, x1, y;

  window.slice_type = "pie";

  slider_val = null;

  svg = null;

  chart_area = null;

  max_pie = null;

  all_clustered_data = {};

  x0 = {};

  x1 = {};

  y = {};

  treemap_props = {
    width: null,
    height: null
  };

  uhero_color5 = d3.scale.ordinal().range(["#0e5a70", "#1e748d", "#368399", "#579fb3", "#88c2d3"]);

  uhero_color10 = d3.scale.ordinal().range(["#03627F", "#1C718B", "#358198", "#4E91A5", "#67A0B2", "#81B0BF", "#9AC0CB", "#B3CFD8", "#CCDFE5", "#E5EFF2"]);

  clustered_color = uhero_color5;

  clustered_color3 = d3.scale.ordinal().range(["#0e5a70", "#4E91A5", "#9AC0CB"]);

  window.treemap_layout = d3.layout.treemap().size([300, 200]).sticky(true).value(function(d) {
    return d[freq].data[slider_val];
  });

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
    var slider_selection;
    slider_selection = d3.select("#slice_slider_selection").text(selected_date());
    if (window.slice_type === 'clustered') {
      return slider_selection.style("visibility", "hidden");
    } else {
      return slider_selection.style("visibility", "visible");
    }
  };

  window.redraw_slice = function(event, ui) {
    var pie_data, pie_slices, sorted_array;
    slider_val = +$("#time_slice_slider_div").val();
    set_date_shown();
    if (window.pied === true) {
      if (window.slice_type === "pie") {
        pie_slices = chart_area.selectAll("path");
        pie_data = pie_slices.data().map(function(d) {
          return d.data;
        });
        pie_slices.data(pie_layout(pie_data), function(d) {
          return d.data.display_name;
        }).attr("d", pie_arc);
        chart_area.select("text.in_pie_label").remove();
        sorted_array = pie_slices.data().sort(function(a, b) {
          return a.value - b.value;
        });
        max_pie = sorted_array.pop();
        return chart_area.selectAll("text").data([max_pie]).enter().append("text").attr("class", "in_pie_label").attr("text-anchor", "middle").attr("transform", function(d) {
          return "translate( " + (pie_arc.centroid(d)) + " )";
        }).append("tspan").attr("class", "pie_slice_name").attr("dy", 20).text(function(d) {
          return d.data.display_name;
        }).append("tspan").attr("class", "pie_slice_value").attr("dy", 20).attr("x", 0).text(function(d) {
          return d.value.toFixed(1);
        });
      } else {
        if (window.slice_type === 'treemap') {
          return window.node.data(treemap_layout.nodes).call(treemap_position);
        } else {
          return window.update_clustered_chart(slider_val);
        }
      }
    }
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
    slice.attr("fill", "#ecffc7");
    chart_area.append("text").attr("class", "pie_label").attr("text-anchor", "middle").attr("transform", "translate( " + (pie_arc.centroid(d)) + " )").append("tspan").attr("class", "pie_slice_name").attr("dy", 20).text(d.data.display_name).append("tspan").attr("class", "pie_slice_value").attr("dy", 20).attr("x", 0).text(d.value.toFixed(1));
    return chart_area.select("text.in_pie_label").remove();
  };

  mouseout_pie = function(d) {
    var slice;
    slice = d3.select(this);
    slice.attr("fill-opacity", "1").attr("fill", function(d) {
      return uhero_color5(d.data.display_name);
    });
    chart_area.select("text.pie_label").remove();
    return chart_area.selectAll("text").data([d]).enter().append("text").attr("class", "in_pie_label").attr("text-anchor", "middle").attr("transform", function(d) {
      return "translate( " + (pie_arc.centroid(d)) + " )";
    }).append("tspan").attr("class", "pie_slice_name").attr("dy", 20).text(d.data.display_name).append("tspan").attr("class", "pie_slice_value").attr("dy", 20).attr("x", 0).text(d.value.toFixed(1));
  };

  set_slider_dates = function(extent) {
    slider_val = extent[1];
    $("#time_slice_slider_div").noUiSlider({
      range: {
        min: extent[0],
        max: extent[1]
      }
    }, true);
    return set_date_shown();
  };

  window.pie_these_series = function(series_data, cluster) {
    var data_extent, pie_notes, sorted_array;
    if (cluster == null) {
      cluster = false;
    }
    if (cluster) {
      window.slice_type = "clustered";
    } else {
      if (series_data[0].display_name === "Construction & Mining") {
        window.slice_type = "treemap";
      } else {
        window.slice_type = "pie";
      }
    }
    data_extent = get_common_dates(series_data);
    set_slider_dates(data_extent);
    chart_area.selectAll("path").remove();
    if (cluster) {
      return window.cluster_these_series(series_data);
    } else {
      sorted_array = pie_layout(series_data).sort(function(a, b) {
        return a.value - b.value;
      });
      d3.select("#pie_heading").text($(".series").first().prev().text().trim().replace("Total", "") + " (" + d3.selectAll($(".series").first().next()).datum().units + ")");
      if (window.slice_type === "pie") {
        max_pie = sorted_array.pop();
        chart_area.selectAll("path").data(pie_layout(series_data), function(d) {
          return d.data.display_name;
        }).enter().append("path").attr("d", pie_arc).attr("fill", function(d) {
          return clustered_color(d.data.display_name);
        }).attr("stroke", "white").attr("stroke-width", 2).on("mouseover", mouseover_pie).on("mouseout", mouseout_pie);
        return chart_area.selectAll("text").data([max_pie]).enter().append("text").attr("class", "in_pie_label").attr("text-anchor", "middle").attr("transform", function(d) {
          return "translate( " + (pie_arc.centroid(d)) + " )";
        }).append("tspan").attr("class", "pie_slice_name").attr("dy", 20).text(function(d) {
          return d.data.display_name;
        }).append("tspan").attr("class", "pie_slice_value").attr("dy", 20).attr("x", 0).text(function(d) {
          return d.value.toFixed(1);
        });
      } else {
        chart_area.attr("transform", "translate(0,50)");
        window.node = chart_area.datum({
          children: series_data
        }).selectAll("rect").data(treemap_layout.nodes).enter().append("rect").call(treemap_position).attr("fill", function(d) {
          switch (d.depth) {
            case 2:
              return uhero_color10(d.parent.display_name);
            case 3:
              return uhero_color10(d.parent.parent.display_name);
            default:
              return uhero_color10(d.display_name);
          }
        }).on("mousemove", treemap_mousemove).on("mouseout", treemap_mouseout);
        pie_notes = svg.append("text").attr("id", "pie_notes").attr("text-anchor", "start").attr("x", 0).attr("y", svg.attr("height") - 40);
        pie_notes.append("tspan").attr("dy", 0).text("The area of each box represents the number of jobs in each category.");
        return pie_notes.append("tspan").attr("dy", 10).text("Colors indicate top-level categories (e.g., Total Government Jobs).").attr("x", 0);
      }
    }
  };

  treemap_mousemove = function(d) {
    var xPosition, yPosition;
    xPosition = d3.event.pageX + 5;
    yPosition = d3.event.pageY + 5;
    d3.select("#treemap_tooltip").style("left", xPosition + "px").style("top", yPosition + "px");
    d3.select("#treemap_tooltip #treemap_tooltip_heading").text(function() {
      switch (d.depth) {
        case 2:
          return "" + d.display_name + " (" + d.parent.display_name + ")";
        case 3:
          return "" + d.display_name + " (" + d.parent.display_name + " - " + d.parent.parent.display_name + ")";
        default:
          return d.display_name;
      }
    });
    d3.select("#treemap_tooltip #treemap_tooltip_percentage").text(function() {
      if (d[freq].yoy[slider_val] != null) {
        return "YOY: " + d[freq].yoy[slider_val].toFixed(1) + "%";
      } else {
        return "YOY: missing";
      }
    });
    d3.select("#treemap_tooltip #treemap_tooltip_value").text(d.value.toFixed(3));
    return d3.select("#treemap_tooltip").classed("hidden", false);
  };

  treemap_mouseout = function(d) {
    return d3.select("#treemap_tooltip").classed("hidden", true);
  };

  treemap_position = function() {
    return this.attr({
      x: function(d) {
        return d.x + "px";
      },
      y: function(d) {
        return d.y + "px";
      },
      width: function(d) {
        return d.dx + "px";
      },
      height: function(d) {
        return d.dy + "px";
      }
    });
  };

  window.visitor_pie_chart = function(container) {
    var center_x, center_y;
    slider_val = all_dates().length - 1;
    svg = set_up_svg(container);
    center_x = svg.attr("width") / 2;
    center_y = svg.attr("height") / 2;
    treemap_props.width = svg.attr("width");
    treemap_props.height = svg.attr("height");
    svg.append("text").attr("id", "pie_heading").attr("text-anchor", "middle").attr("x", center_x).attr("y", 20);
    chart_area = svg.append("g").attr("id", "pie_chart_area").attr("transform", "translate(" + center_x + "," + center_y + ")");
    return svg.append("text").attr("id", "slice_slider_selection").attr("text-anchor", "middle").attr("x", center_x).attr("y", svg.attr("height") - 10).text("2013");
  };

  x = d3.scale.linear().clamp(true).range([0, 15]);

  y = d3.scale.linear();

  x0 = d3.scale.ordinal();

  selected_dates = function() {
    return all_dates().slice(slider_val - 4, +slider_val + 1 || 9e9);
  };

  selected_data = function(d) {
    var _i, _ref, _results;
    return (function() {
      _results = [];
      for (var _i = _ref = slider_val - 4; _ref <= slider_val ? _i <= slider_val : _i >= slider_val; _ref <= slider_val ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this).map(function(index) {
      var period;
      period = {
        period: all_dates()[index]
      };
      period.series = d.map(function(series) {
        return {
          name: series.display_name,
          value: +series[freq].yoy[index]
        };
      });
      return period;
    });
  };

  window.cluster_these_series = function(series_data) {
    var data, height, legend, period, seriesNames, width, xAxis, yAxis;
    all_clustered_data = series_data;
    width = svg.attr('width');
    height = svg.attr('height') - 30;
    x0 = d3.scale.ordinal().rangeRoundBands([0, width], 0.2);
    x1 = d3.scale.ordinal();
    y = d3.scale.linear().range([height, 0]);
    xAxis = d3.svg.axis().scale(x0).orient("bottom");
    yAxis = d3.svg.axis().scale(y).orient("right").tickFormat(d3.format(".2s"));
    data = selected_data(series_data);
    seriesNames = ["Real Personal Income", "Total Visitor Days", "Total Non-farm Payrolls"];
    x0.domain(data.map(function(d) {
      return d.period;
    }));
    x1.domain(seriesNames).rangeRoundBands([0, x0.rangeBand()]);
    y.domain([-20, 20]);
    svg.append("g").attr("class", "x axis").attr("transform", "translate(0," + (height + 30) + ")").call(xAxis);
    svg.append("text").text("Growth Rate").attr("y", 20).attr("x", width / 2).attr("id", "cluster_heading").style("text-anchor", "middle");
    svg.append("g").attr("class", "y axis").attr("transform", "translate(" + width + ", 30)").call(yAxis);

    /*
      .append("text")
       *.attr("transform", "translate(-10, 0)")
       *.attr("transform", "rotate(-90), translate(0, 30)")
      .attr("y", 20)
       *.attr("dy", ".71em")
      .attr("x",-(width/2))
      .attr("id","cluster_heading")
      .style("text-anchor", "middle") #text-align
      .text("Growth Rate")
     */
    period = svg.selectAll(".period").data(data).enter().append("g").attr("class", "g").attr("transform", function(d) {
      return "translate(" + x0(d.period) + ",30)";
    });
    period.selectAll("rect").data(function(d) {
      return d.series;
    }).enter().append("rect").classed("series_bars", true).attr("width", x1.rangeBand()).attr("x", function(d) {
      return x1(d.name);
    }).attr("y", function(d) {
      return y(d3.max([0, d3.min([20, d.value])]));
    }).attr("height", function(d) {
      return y(0) - y(d3.min([20, Math.abs(d.value)]));
    }).style("fill", function(d) {
      return clustered_color3(d.name);
    });
    legend = svg.selectAll(".legend").data(seriesNames.slice()).enter().append("g").attr("class", "legend").attr("transform", function(d, i) {
      return "translate(-10," + i * 20 + ")";
    });
    legend.append("rect").attr("x", width - 18).attr("y", 39).attr("width", 18).attr("height", 18).style("fill", clustered_color3);
    return legend.append("text").attr("x", width - 24).attr("y", 47).attr("dy", ".35em").classed("clustered_bar_legend", true).style("text-anchor", "end").text(function(d) {
      return d;
    });
  };

  window.update_clustered_chart = function(slider_val) {
    var data, height, legend, period, series, seriesNames, width, xAxis;
    seriesNames = ["Real Personal Income", "Total Visitor Days", "Total Non-farm Payrolls"];
    data = selected_data(all_clustered_data);
    width = svg.attr('width');
    height = svg.attr('height');
    x0 = d3.scale.ordinal().rangeRoundBands([0, width], 0.1);
    x0.domain(data.map(function(d) {
      return d.period;
    }));
    xAxis = d3.svg.axis().scale(x0).orient("bottom");
    svg.selectAll(".x.axis").attr("transform", "translate(0," + height + ")").call(xAxis);
    svg.selectAll("rect.series_bars").remove();
    period = svg.selectAll(".period").data(data);
    period.enter().append("g").attr("transform", function(d) {
      return "translate(" + x0(d.period) + ",30)";
    });
    series = period.selectAll("rect").data(function(d) {
      return d.series;
    });
    series.remove();
    series.enter().append("rect").classed("series_bars", true).attr("width", x1.rangeBand()).attr("x", function(d) {
      return x1(d.name);
    }).attr("y", function(d) {
      return y(d3.max([0, d3.min([20, d.value])]));
    }).attr("height", function(d) {
      return y(0) - y(d3.min([20, Math.abs(d.value)]));
    }).style("fill", function(d) {
      return clustered_color3(d.name);
    });
    series.exit().remove();
    svg.selectAll(".legend").remove();
    legend = svg.selectAll(".legend").data(seriesNames.slice()).enter().append("g").attr("class", "legend").attr("transform", function(d, i) {
      return "translate(-10," + i * 20 + ")";
    });
    legend.append("rect").attr("x", width - 18).attr("y", 39).attr("width", 18).attr("height", 18).style("fill", clustered_color3);
    return legend.append("text").attr("x", width - 24).attr("y", 47).attr("dy", ".35em").classed("clustered_bar_legend", true).style("text-anchor", "end").text(function(d) {
      return d;
    });
  };

}).call(this);
