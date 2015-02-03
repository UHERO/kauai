---
---

dates = { a: [], q:[] , m:[] }

window.data_categories =
  "major indicators": { width: 130, slug: "major", title: "Major Indicators", default_freq: "a"}
  "visitor industry": { width: 140, slug: "vis", title: "Visitor Industry", default_freq: "q" }
  "labor market": { width: 100, slug: "jobs", title: "Labor Market", default_freq: "q" }
  "personal income": { width: 120, slug: "income", title: "Personal Income", default_freq: "a"}
  "construction": { width: 100, slug: "const", title: "Construction", default_freq: "a" }
  "county budget": { width: 120, slug: "county_rev", title: "County Budget", default_freq: "a" }
#dt changed 'labor' to 'labor market', county revenue' to 'county budget' -- does this have any effect?

yoy = (d,i,array,f) ->
  return null if d is null or i is 0
  offset = { a: 1, q: 4, m: 12 }[f]
  last = array[i-offset]
  if last is null then null else (d-last) / last * 100
  
spark_data = (name, data, scale_factor) ->
  if !scale_factor? then scale_factor = 1
  data.map((row) -> if row[name] == "" then null else +row[name] * scale_factor )

ytd = (series_data, year) ->
  series_data.map (d, i, array) ->
    # create ytd sum
    ytd_sum = d
    j = i - 1
    while year[i] == year[j]
      ytd_sum = ytd_sum + array[j]
      j = j - 1
    ytd_sum

set_data_for = (f, series, data) ->
  #series_data = spark_data("#{series.udaman_name}.#{f.toUpperCase()}", data[f])
  series_data = spark_data("#{series.udaman_name}.#{f.toUpperCase()}", data[f], series.scale_factor)
  year = data[f].map (d) -> d.date.slice(0,4)
  ytd_data = ytd(series_data, year)
  peak = d3.max(series_data)
  trough = d3.min(series_data)
  last_i = series_data.length-1
  discard = last_i while (series_data[last_i] == null and last_i -= 1)

  series[f] =
    data: series_data
    year: year
    ytd: ytd_data
    date: data[f].map (d) -> format_d d.date, f
    ytd_change: ytd_data.map((d, i, array) -> yoy(d, i, array, f))
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

format_d = (date, f) ->
  q_map = {"01":"1", "04":"2", "07":"3", "10":"4" }
  switch f
    when "a" then date.slice(0,4)
    when "q" then date.slice(0,4)+"Q"+q_map[date.slice(5,7)]
    when "m" then date.slice(0,4)+"M"+date.slice(5,7)
    
window.prepare_all_data = (meta, data) ->
  dates[f] = data[f].map((d)->format_d(d.date,f)) for f in d3.keys(data)
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
