---
---

dates = { a: [], q:[] , m:[] }

window.data_categories = 
  "major indicators": { width: 130, slug: "major" }
  "visitor industry": { width: 140, slug: "vis" }
  "labor": { width: 100, slug: "labor" }
  "personal income": { width: 120, slug: "income" }
  "construction": { width: 100, slug: "const" }
  "county revenue": { width: 120, slug: "county_rev" }


yoy = (d,i,array,f) ->
  return null if d is null or i is 0
  offset = { a: 1, q: 4, m: 12 }[f]
  last = array[i-offset]
  if last is null then null else (d-last) / last * 100
  
  
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
    yoy: series_data.map((d,i,array) -> yoy(d,i,array,f))
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
  prep_group_data group, data for group in meta.series_groups
  meta.dates = dates
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