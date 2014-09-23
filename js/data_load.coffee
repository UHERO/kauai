---
---

freq = "a"
dates = { a: [], q:[] , m:[] }

#should delete all of these eventually
csv_data_a = []
csv_headers = {}
window.ts_annual = {}
window.ts_by_category = {}
window.all_dates = []

window.data_categories = 
  "major indicators": { width: 130, slug: "major" }
  "visitor industry": { width: 140, slug: "vis" }
  "labor": { width: 100, slug: "labor" }
  "personal income": { width: 120, slug: "income" }
  "construction": { width: 100, slug: "const" }
  "county revenue": { width: 120, slug: "county_rev" }
  
get_all_csv_data_for_series = (series) ->
  array_to_populate = []
  array_to_populate.push({ period:row.period.slice(0,4) , val:row[series] }) for row in csv_data_a
  array_to_populate

filter_and_format_time_series = (series_data) ->
  series_data.filter((d) -> d.val != "")
    .map((d) -> 
      period: d.period
      val:+d.val
    )

spark_formatted_data = (series) ->
  get_all_csv_data_for_series(series).map((d)->
    if d.val == "" then null else +d.val
  )

set_ts_data = (series) ->
  series_data = filter_and_format_time_series get_all_csv_data_for_series(series)
  ts_annual[series] =
    name: series 
    data: series_data
    category: csv_headers.category[series]
    spark_data: spark_formatted_data(series)

series_array_from_csv_data = (csv_data) ->
  d3.keys(csv_data[0]).slice(1)

prepare_csv_headers = (csv_data) ->
  h = csv_data.slice(0,4)
  display_names: h[0]
  category: h[1]
  primary: "secondary"#h[2]
  full_name: h[3]

window.prepare_annual_data = (data) ->
  csv_data_a = data.slice(5)
  csv_headers = prepare_csv_headers data

  window.all_dates = csv_data_a.map((d) -> +d.period.slice(0,4))
  set_ts_data series for series in series_array_from_csv_data(data)
  window.ts_by_category = d3.nest().key((d) -> d.category).map(d3.values(ts_annual))


# ------------ Keeper data stuff -------------

spark_data = (name, data) ->
  data.map((row) -> if row[name] == "" then null else +row[name] )

set_data_for = (f, series, data) ->
  series_data = spark_data("#{series.udaman_name}.#{f.toUpperCase()}", data[f])
  peak = d3.max(series_data)
  trough = d3.min(series_data)
  last_i = series_data.length-1
  discard = last_i while (series_data[last_i] == null and last_i -= 1)

  series[f] =
    data: series_data
    yoy: []
    peak: peak
    trough: trough
    last: series_data[last_i]
    peak_i: series_data.indexOf(peak)
    trough_i: series_data.indexOf(trough)
    last_i: last_i
    
prep_series_data = (series, data) ->
  (set_data_for f, series, data if series[f]) for f in ['a','q', 'm']
    
  if series.children? and series.children.length > 0
    prep_series_data s, data for s in series.children
    
prep_group_data = (series_group, data) ->
  prep_series_data series, data for series in series_group.series_list

window.prepare_all_data = (meta, data) ->
  dates[f] = data[f].map((d)->d.date) for f in d3.keys(data)
  console.log(dates)
  prep_group_data group, data for group in meta.series_groups
  meta
  
window.load_page_data = (page_slug, callback) ->
  meta_file = "data/#{page_slug}_meta.json"
  data_file_a = "data/#{page_slug}_a.csv"
  data_file_q = "data/#{page_slug}_q.csv"
  data_file_m = "data/#{page_slug}_m.csv"
  
  q = queue()
  q.defer(d3.json, meta_file)
  q.defer(d3.csv, data_file_a)
  q.defer(d3.csv, data_file_q)
  q.defer(d3.csv, data_file_m)
  q.awaitAll((error, results) -> 
    meta = results[0]
    data = { a: results[1], q: results[2], m: results[3] }
    prepared_data = prepare_all_data(meta, data)
    callback(prepared_data)
  )