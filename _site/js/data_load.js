(function() {
  var csv_data_a, csv_headers, dates, filter_and_format_time_series, freq, get_all_csv_data_for_series, prep_group_data, prep_series_data, prepare_csv_headers, series_array_from_csv_data, set_data_for, set_ts_data, spark_data, spark_formatted_data;

  freq = "a";

  dates = {
    a: [],
    q: [],
    m: []
  };

  csv_data_a = [];

  csv_headers = {};

  window.ts_annual = {};

  window.ts_by_category = {};

  window.all_dates = [];

  window.data_categories = {
    "major indicators": {
      width: 130,
      slug: "major"
    },
    "visitor industry": {
      width: 140,
      slug: "vis"
    },
    "labor": {
      width: 100,
      slug: "labor"
    },
    "personal income": {
      width: 120,
      slug: "income"
    },
    "construction": {
      width: 100,
      slug: "const"
    },
    "county revenue": {
      width: 120,
      slug: "county_rev"
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

  spark_data = function(name, data) {
    return data.map(function(row) {
      if (row[name] === "") {
        return null;
      } else {
        return +row[name];
      }
    });
  };

  set_data_for = function(f, series, data) {
    var discard, last_i, peak, series_data, trough;
    series_data = spark_data("" + series.udaman_name + "." + (f.toUpperCase()), data[f]);
    peak = d3.max(series_data);
    trough = d3.min(series_data);
    last_i = series_data.length - 1;
    while (series_data[last_i] === null && (last_i -= 1)) {
      discard = last_i;
    }
    return series[f] = {
      data: series_data,
      yoy: [],
      peak: peak,
      trough: trough,
      last: series_data[last_i],
      peak_i: series_data.indexOf(peak),
      trough_i: series_data.indexOf(trough),
      last_i: last_i
    };
  };

  prep_series_data = function(series, data) {
    var f, s, _i, _j, _len, _len1, _ref, _ref1, _results;
    _ref = ['a', 'q', 'm'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      f = _ref[_i];
      if (series[f]) {
        set_data_for(f, series, data);
      }
    }
    if ((series.children != null) && series.children.length > 0) {
      _ref1 = series.children;
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        s = _ref1[_j];
        _results.push(prep_series_data(s, data));
      }
      return _results;
    }
  };

  prep_group_data = function(series_group, data) {
    var series, _i, _len, _ref, _results;
    _ref = series_group.series_list;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      series = _ref[_i];
      _results.push(prep_series_data(series, data));
    }
    return _results;
  };

  window.prepare_all_data = function(meta, data) {
    var f, group, _i, _j, _len, _len1, _ref, _ref1;
    _ref = d3.keys(data);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      f = _ref[_i];
      dates[f] = data[f].map(function(d) {
        return d.date;
      });
    }
    console.log(dates);
    _ref1 = meta.series_groups;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      group = _ref1[_j];
      prep_group_data(group, data);
    }
    return meta;
  };

  window.load_page_data = function(page_slug, callback) {
    var data_file_a, data_file_m, data_file_q, meta_file, q;
    meta_file = "data/" + page_slug + "_meta.json";
    data_file_a = "data/" + page_slug + "_a.csv";
    data_file_q = "data/" + page_slug + "_q.csv";
    data_file_m = "data/" + page_slug + "_m.csv";
    q = queue();
    q.defer(d3.json, meta_file);
    q.defer(d3.csv, data_file_a);
    q.defer(d3.csv, data_file_q);
    q.defer(d3.csv, data_file_m);
    return q.awaitAll(function(error, results) {
      var data, meta, prepared_data;
      meta = results[0];
      data = {
        a: results[1],
        q: results[2],
        m: results[3]
      };
      prepared_data = prepare_all_data(meta, data);
      return callback(prepared_data);
    });
  };

}).call(this);
