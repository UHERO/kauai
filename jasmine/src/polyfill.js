
/**
Necessary polyfills
 */

(function() {
  if (!Array.prototype.findIndex) {
    Array.prototype.findIndex = function(predicate) {
      var i, length, list, thisArg, value;
      if (typeof this === "undefined" || this === null) {
        throw new TypeError("Array.prototype.find called on null or undefined");
      }
      if (typeof predicate !== "function") {
        throw new TypeError("predicate must be a function");
      }
      list = Object(this);
      length = list.length >>> 0;
      thisArg = arguments[1];
      value = void 0;
      i = 0;
      while (i < length) {
        value = list[i];
        if (predicate.call(thisArg, value, i, list)) {
          return i;
        }
        i++;
      }
      return -1;
    };
  }

}).call(this);
