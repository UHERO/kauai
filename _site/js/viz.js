(function() {
  var page_setup, render_loaded_data, set_headline, set_up_dashboard_elements, set_up_div, set_up_nav;

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
    });
  };

  set_headline = function(text) {
    return d3.select("#headline").text(text);
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

  set_up_div = function(elem) {
    return d3.select("#charts_area").append("div").attr("class", "dashboard_element").attr("id", elem.id).style("width", elem.width + "px").style("height", elem.height + "px").call(elem.type_function);
  };

  page_setup = function() {
    collapse(d3.select("#cat_Construction"));
    collapse(d3.select("#cat_Employment"));
    collapse(d3.select("#cat_General"));
    return collapse(d3.select("#cat_Income"));
  };

  render_loaded_data = function(data) {
    var dashboard_elements;
    prepare_annual_data(data);
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
    create_data_table();
    set_up_sliders();
    return page_setup();
  };

  set_up_nav();

  set_headline("In 2013, per person per trip spending increaed by 9.63% compared to the previous year");

  d3.csv("data/kauai_data_annual.csv", render_loaded_data);

}).call(this);
