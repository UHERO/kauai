(function() {
  var clear_dashboard_elements, clear_data_table, clear_previous_page, clear_sliders, page_setup, render_page, set_headline, set_single_slider_in_div, set_slider_in_div, set_up_dashboard_elements, set_up_div, set_up_nav, set_up_sliders;

  window.freq = "q";

  window.series_to_class = function(series_name) {
    return series_name.replace(".", "_").replace("@", "_").replace("%", "pct");
  };

  window.set_up_svg = function(container) {
    var height, width;
    width = +container.style("width").slice(0, -2);
    height = +container.style("height").slice(0, -2);
    return container.append("svg").attr("id", container.attr("id") + "_svg").attr("height", height).attr("width", width);
  };

  set_up_nav = function() {
    return d3.select("div#nav").selectAll("div.nav_link").data(d3.entries(data_categories)).enter().append("div").attr("class", "nav_link").attr("id", function(d) {
      return d.key.replace(" ", "_");
    }).style("width", function(d) {
      return d.value.width + "px";
    }).text(function(d) {
      return d.key;
    }).on("click", function(d) {
      return load_page(d.value);
    });
  };

  set_headline = function(text) {
    return d3.select("#headline").text(text);
  };

  set_slider_in_div = function(div_id, dates, pos1, pos2, slide_func) {
    d3.select("#" + div_id).remove();
    d3.select("#" + div_id.replace("div", "container")).insert("div", "div#buttons").attr("id", div_id).attr("class", "slider");
    $("#" + div_id).slider({
      range: true,
      min: 0,
      max: dates.length - 1,
      values: [pos1, pos2],
      slide: slide_func
    });
    d3.select("#" + div_id).datum(dates);
    return d3.selectAll("#" + div_id + " a").data([1, 2]).attr("slider", function(d) {
      if (d === 1) {
        return "left";
      }
      if (d === 2) {
        return "right";
      }
    });
  };

  set_single_slider_in_div = function(div_id, dates, pos1, pos2, slide_func) {
    d3.select("#" + div_id).remove();
    d3.select("#" + div_id.replace("div", "container")).insert("div", "div#buttons").attr("id", div_id).attr("class", "slider");
    $("#" + div_id).slider({
      min: 0,
      max: dates.length - 1,
      value: pos2,
      slide: slide_func
    });
    return d3.select("#" + div_id).datum(dates);
  };

  set_up_sliders = function(dates) {
    set_slider_in_div("sparkline_slider_div", dates, 0, dates.length - 1, trim_sparklines);
    set_slider_in_div("line_chart_slider_div", dates, 0, dates.length - 1, trim_time_series);
    set_single_slider_in_div("time_slice_slider_div", dates, 0, dates.length - 1, redraw_slice);
    return set_single_slider_in_div("datatable_slider_div", dates, 0, dates.length - 1, slide_table);
  };

  set_up_div = function(elem) {
    return d3.select("#charts_area").append("div").attr("class", "dashboard_element").attr("id", elem.id).style("width", elem.width + "px").style("height", elem.height + "px").call(elem.type_function);
  };

  set_up_dashboard_elements = function(elements) {
    var elem, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = elements.length; _i < _len; _i++) {
      elem = elements[_i];
      _results.push(set_up_div(elem));
    }
    return _results;
  };

  page_setup = function() {
    collapse(d3.select("#cat_Construction"));
    collapse(d3.select("#cat_Employment"));
    collapse(d3.select("#cat_General"));
    return collapse(d3.select("#cat_Income"));
  };

  clear_dashboard_elements = function() {
    return d3.selectAll("#charts_area .dashboard_element").remove();
  };

  clear_data_table = function() {
    return d3.selectAll("#series_display .category").remove();
  };

  clear_sliders = function() {
    set_slider_in_div("sparkline_slider_div", dates, 0, dates.length - 1, trim_sparklines);
    set_slider_in_div("line_chart_slider_div", dates, 0, dates.length - 1, trim_time_series);
    set_single_slider_in_div("time_slice_slider_div", dates, 0, dates.length - 1, redraw_slice);
    return set_single_slider_in_div("datatable_slider_div", dates, 0, dates.length - 1, slide_table);
  };

  clear_previous_page = function() {
    clear_dashboard_elements();
    return clear_data_table();
  };

  render_page = function(page_data) {
    var dashboard_elements;
    clear_previous_page();
    set_up_sliders(page_data.dates[freq]);
    dashboard_elements = [
      {
        id: "line_chart",
        width: 425,
        height: 300,
        type_function: line_chart
      }, {
        id: "pie_chart",
        width: 300,
        height: 300,
        type_function: visitor_pie_chart
      }
    ];
    set_up_dashboard_elements(dashboard_elements);
    create_data_table(page_data);
    set_up_line_chart_paths(d3.selectAll("#series_display .series").data());
    display_line_and_bar_chart(page_data.series_groups[0].series_list[0]);
    return pie_these_series(page_data.series_groups[0].series_list[0].children);
  };

  window.load_page = function(data_category) {
    return load_page_data(data_category.slug, function(data) {
      set_headline(data_category.title);
      return render_page(data);
    });
  };

  set_up_nav();

  load_page(data_categories["visitor industry"]);

}).call(this);
