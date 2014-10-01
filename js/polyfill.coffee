---
---

###*
Necessary polyfills
###

# used in time_slice_chart.js
# Polyfillfrom https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/findIndex
# transformed by js2coffee.org
unless Array::findIndex
  Array::findIndex = (predicate) ->
    throw new TypeError("Array.prototype.find called on null or undefined")  unless this?
    throw new TypeError("predicate must be a function")  if typeof predicate isnt "function"
    list = Object(this)
    length = list.length >>> 0
    thisArg = arguments[1]
    value = undefined
    i = 0

    while i < length
      value = list[i]
      return i  if predicate.call(thisArg, value, i, list)
      i++
    -1
