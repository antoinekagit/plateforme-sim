"use strict";

// shorter alias for console
var c = console;
var print = function (m) { c.log(m); return m };

// checking if a variable is not undefined or null
var isDef = function (x) { return ! (x === null || x === undefined); };
var isNotDef = function (x) { return ! isDef(x) };
// identity function
var identity = function (x) { return x; };
// if x is not def use defaultt
var ifNotDef = function (x, defaultVal) {
    return isDef(x) ? x : defaultVal;
};
// pairs and projections
var pair  = function (l, r) { return [l, r]; },
    left  = function (p)    { return p[0]  ; },
    right = function (p)    { return p[1]  ; };

var getp = function (p) { return function (arr) {
  return Array.map(arr, function (obj) { return obj[p] })}};

var min = function (arr) {
  var min = null;
  Array.forEach(arr, function(elt) {
    if (isNotDef(min)) min = elt;
    else if (elt < min) min = elt; });
  return min; }

var max = function (arr) {
  var max = null;
  Array.forEach(arr, function(elt) {
    if (isNotDef(max)) max = elt;
    else if (elt > max) max = elt; });
  return max; }

var minBy = function (arr, f) {
  var min = null;
  Array.forEach(arr, function(elt) {
    var eltf = f(elt)
    if (isNotDef(min)) min = eltf;
    else if (eltf < min) min = eltf; });
  return min; }

var maxBy = function (arr, f) {
  var max = null;
  Array.forEach(arr, function(elt) {
    var eltf = f(elt);
    if (isNotDef(max)) max = eltf;
    else if (eltf > max) max = eltf; });
  return max; }

var seq = function (f, g) {
  return function (x) { return g(f(x)) }};

var flat = function (arrArr) {
  var res = Array();
  Array.map(arrArr, function(arr) {
    return Array.forEach(arr, function (elt) {
      res.push(elt);
    });
  });
  return res;
};

var bounded = function (min, value, max) {
  return Math.max(min, Math.min(value, max))
};

var riotNullHandler = function (e) { e.preventUpdate = true }

var unique = function(arr) {
    var o = {}, i, l = arr.length, r = [];
    for(i = 0 ; i < l ; i += 1) { o[arr[i]] = arr[i]; }
    for(i in o) r.push(o[i]);
    return r;
};
