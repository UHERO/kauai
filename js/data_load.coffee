---
---

csv_data_a = []
csv_headers = {}
window.ts_annual = {}
window.ts_by_category = {}

window.all_dates = []

window.data_categories = 
  "major indicators": { width: 130 }
  "visitor industry": { width: 140 }
  "labor": { width: 100 }
  "personal income": { width: 120 }
  "construction": { width: 100 }
  "county revenue": { width: 120 }
  
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

  # console.log(ts_annual)
  # console.log(window.ts_by_category)
  # console.log(all_dates)