(function() {
  var csv_data_a, csv_headers, filter_and_format_time_series, get_all_csv_data_for_series, prepare_csv_headers, series_array_from_csv_data, set_ts_data, spark_formatted_data;

  csv_data_a = [];

  csv_headers = {};

  window.ts_annual = {};

  window.ts_by_category = {};

  window.all_dates = [];

  window.data_categories = {
    "major indicators": {
      width: 130
    },
    "visitor industry": {
      width: 140
    },
    "labor": {
      width: 100
    },
    "personal income": {
      width: 120
    },
    "construction": {
      width: 100
    },
    "county revenue": {
      width: 120
    }
  };

  get_all_csv_data_for_series = function(series) {
    var array_to_populate, row, _i, _len;
    array_to_populate = [];
    for (_i = 0, _len = csv_data_a.length; _i < _len; _i++) {
      row = csv_data_a[_i];
      array_to_populate.push({
        period: row.period.slice(0, 4),
        val: row[series]
      });
    }
    return array_to_populate;
  };

  filter_and_format_time_series = function(series_data) {
    return series_data.filter(function(d) {
      return d.val !== "";
    }).map(function(d) {
      return {
        period: d.period,
        val: +d.val
      };
    });
  };

  spark_formatted_data = function(series) {
    return get_all_csv_data_for_series(series).map(function(d) {
      if (d.val === "") {
        return null;
      } else {
        return +d.val;
      }
    });
  };

  set_ts_data = function(series) {
    var series_data;
    series_data = filter_and_format_time_series(get_all_csv_data_for_series(series));
    return ts_annual[series] = {
      name: series,
      data: series_data,
      category: csv_headers.category[series],
      spark_data: spark_formatted_data(series)
    };
  };

  series_array_from_csv_data = function(csv_data) {
    return d3.keys(csv_data[0]).slice(1);
  };

  prepare_csv_headers = function(csv_data) {
    var h;
    h = csv_data.slice(0, 4);
    return {
      display_names: h[0],
      category: h[1],
      primary: "secondary",
      full_name: h[3]
    };
  };

  window.prepare_annual_data = function(data) {
    var series, _i, _len, _ref;
    csv_data_a = data.slice(5);
    csv_headers = prepare_csv_headers(data);
    window.all_dates = csv_data_a.map(function(d) {
      return +d.period.slice(0, 4);
    });
    _ref = series_array_from_csv_data(data);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      series = _ref[_i];
      set_ts_data(series);
    }
    return window.ts_by_category = d3.nest().key(function(d) {
      return d.category;
    }).map(d3.values(ts_annual));
  };

}).call(this);
