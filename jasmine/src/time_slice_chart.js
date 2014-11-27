(function() {
  var all_dates, chart_area, color, dates_extent, get_common_dates, get_data_index_extent, max_pie, mouseout_pie, mouseover_pie, pie_arc, pie_layout, selected_date, set_date_shown, set_slider_dates, slider_val, svg, treemap_mousemove, treemap_mouseout, treemap_position, treemap_props;

  window.slice_type = "pie";

  slider_val = null;

  svg = null;

  chart_area = null;

  max_pie = null;

  treemap_props = {
    width: null,
    height: null
  };

  color = d3.scale.category20c();

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
    return d3.select("#slice_slider_selection").text(selected_date());
  };

  window.redraw_slice = function(event, ui) {
    var pie_data, pie_slices, sorted_array;
    slider_val = +$("#time_slice_slider_div").val();
    set_date_shown();
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
      console.log(max_pie);
      return chart_area.selectAll("text").data([max_pie]).enter().append("text").attr("class", "in_pie_label").attr("text-anchor", "middle").attr("transform", function(d) {
        return "translate( " + (pie_arc.centroid(d)) + " )";
      }).append("tspan").attr("class", "pie_slice_name").attr("dy", 20).text(function(d) {
        return d.data.display_name;
      }).append("tspan").attr("class", "pie_slice_value").attr("dy", 20).attr("x", 0).text(function(d) {
        return d.value.toFixed(1);
      });
    } else {
      return window.node.data(treemap_layout.nodes).call(treemap_position);
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
    slice.attr("fill-opacity", ".3");
    chart_area.append("text").attr("class", "pie_label").attr("text-anchor", "middle").attr("transform", "translate( " + (pie_arc.centroid(d)) + " )").append("tspan").attr("class", "pie_slice_name").attr("dy", 20).text(d.data.display_name).append("tspan").attr("class", "pie_slice_value").attr("dy", 20).attr("x", 0).text(d.value.toFixed(1));
    return chart_area.select("text.in_pie_label").remove();
  };

  mouseout_pie = function(d) {
    var slice;
    slice = d3.select(this);
    slice.attr("fill-opacity", "1");
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

  window.pie_these_series = function(series_data) {
    var data_extent, pie_notes, sorted_array;
    console.log("window.pie_these_series was called");
    console.log(series_data);
    if (series_data[0].display_name === "Construction & Mining") {
      window.slice_type = "treemap";
    } else {
      window.slice_type = "pie";
    }
    data_extent = get_common_dates(series_data);
    set_slider_dates(data_extent);
    chart_area.selectAll("path").remove();
    sorted_array = pie_layout(series_data).sort(function(a, b) {
      return a.value - b.value;
    });
    if (window.slice_type === "pie") {
      max_pie = sorted_array.pop();
      chart_area.selectAll("path").data(pie_layout(series_data), function(d) {
        return d.data.display_name;
      }).enter().append("path").attr("d", pie_arc).attr("fill", function(d) {
        return color(d.data.display_name);
      }).attr("stroke", "white").attr("stroke-width", 2).on("mouseover", mouseover_pie).on("mouseout", mouseout_pie);
      chart_area.selectAll("text").data([max_pie]).enter().append("text").attr("class", "in_pie_label").attr("text-anchor", "middle").attr("transform", function(d) {
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
            return color(d.parent.display_name);
          case 3:
            return color(d.parent.parent.display_name);
          default:
            return color(d.display_name);
        }
      }).on("mousemove", treemap_mousemove).on("mouseout", treemap_mouseout);
      pie_notes = svg.append("text").attr("id", "pie_notes").attr("text-anchor", "start").attr("x", 0).attr("y", svg.attr("height") - 40);
      pie_notes.append("tspan").attr("dy", 0).text("The area of each box represents the number of jobs in each category.");
      pie_notes.append("tspan").attr("dy", 10).text("Colors indicate top-level categories (e.g., Total Government Jobs).").attr("x", 0);
    }
    return d3.select("#pie_heading").text($(".series.parent").first().prev().text().trim().replace("Total", "") + " (" + d3.selectAll($(".series.parent").first().next()).datum().units + ")");
  };

  treemap_mousemove = function(d) {
    var xPosition, yPosition;
    xPosition = d3.event.pageX + 5;
    yPosition = d3.event.pageY + 5;
    console.log(d);
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
      return "YOY: " + d[freq].yoy[slider_val].toFixed(1) + "%";
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

}).call(this);
