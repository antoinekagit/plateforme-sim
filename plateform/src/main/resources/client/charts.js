/*

# chart
width: int
height: int
axesWidth: int
axesHeight: int
displayInfo: bool
axeYFormat: d3 format
series: array

# serie
name: string
dataF: function like getProp
displayLine: bool
displayPoints: bool
color: css color
lineStrokeWidth: int
format: d3 format

*/

var doMap = function (f) {
  return function (datas) {
    return datas.map(function (elt) {
      return { x: elt.period, y: f(elt.d) } })}};
var getProp = function (prop) {
  return doMap(function (m) { return m[prop] })};

var charts = {
  cash: { series: [
    { name:"cash bank", dataName:"cashBank", color:"green" },
    { name:"cash firms", dataName:"cashFirms", color:"red" },
    { name:"cash menages", dataName:"cashMenages", color:"blue" }
  ]},

  biens: { series: [
    { name:"biens firms", dataName:"biensFirms", color:"red" },
    { name:"biens menages", dataName:"biensMenages", color:"blue" }
  ]},

 production: { series: [
  	      { name:"biens produits", dataName:"biensProduits", color:"red" }
	      ]},
  prix: { series: [
    { name:"prix moyen firmes", dataName:"prixMoyenFirms", color:"red" }
  ]},

  achats: { series: [
    { name:"achats", dataName:"nbAchats", color:"orange" }
  ]}
                                                            
};

var panels = {
  /*general: [ "cash" ],*/
  all: Object.keys(charts)
};
