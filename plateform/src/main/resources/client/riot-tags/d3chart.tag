<d3chart class="chart" >

  <!-- legend -->
  <span>{opts.props.name}</span>
  <ul name="legends" class="legends" >

    <li class="legend" >
      <strong>x</strong>
      {opts.props.type == "xIsPeriods" ? "period" : opts.props.x.name}
      <span class="value" ></span>
    </li>

    <li each={series} class="legend" >
      <span class="square" style={"color: " + color + ";"} >&#x25A0;</span>
      <span>{name}</span><span class="value" ></span>
    </li>
  </ul>

  <!-- data svg -->
  <svg riot-width={opts.props.width} riot-height={opts.props.height} >
    <g name="xAxis" class="axis" riot-transform={axeBotTr} ></g>
    <g name="yAxis" class="axis" riot-transform={axeLeftTr} ></g>
    
    <svg name="dataZone" class={"dataZone crosshair"}
	 riot-x={dataZoneX} riot-y={dataZoneY}
	 riot-width={dataZoneW} riot-height={dataZoneH}
	 onmousemove={mouseOnGraph}
	 onmousedown={dataZoneMouseDown} onmouseup={dataZoneMouseUp}
	 onmouseleave={dataZoneMouseLeave} >
      <rect class="dataBackground" width="100%" height="100%" ></rect>
      <rect class="zoomZone" height="100%"
	    riot-x={zoomZoneX} riot-width={zoomZoneW} ></rect>
    </svg>
  </svg>
  
  <script>

   var self = this;
   
   // ====================================
   // ===== INIT
   // ====================================

   var axeLeftW = 50, axesH = 20, padTop = padRight = 10;
   self.scaleX = null;
   self.scaleY = null;
   self.dataZoneW = dataZoneH = 0;
   self.dataZoneX = axeLeftW;
   self.dataZoneY = padTop;
   self.axeLeftTr = "";
   self.axeBotTr = "";
   self.series = Array();
   self.lastAlias = null;
   self.lastStartZoom = null;
   self.lastEndZoom = null;
   self.dataZoneMouseDown = riotNullHandler;
   self.dataZoneMouseUp = riotNullHandler;
   self.dataZoneMouseLeave = self.dataZoneMouseUp;
   self.zoomZoneX = 0;
   self.zoomZoneW = 0;
   
   // ====================================
   // ===== UPDATE
   // ====================================
   
   self.on("update", function () {
     
     // Update coords
     self.dataZoneW = opts.props.width - axeLeftW - padRight;
     self.dataZoneH = opts.props.height - axesH - padTop;
     self.axeLeftTr = "translate(" + axeLeftW + "," + self.dataZoneY + ")";
     self.axeBotTr = "translate(" + axeLeftW + ","
		   + (self.dataZoneH + self.dataZoneY) + ")";

     self.dataZoneMouseDown = isDef(opts.selectstartzoom) ?
			      riotNullHandler : self.getStartZoom;
     self.dataZoneMouseUp = isDef(opts.selectstartzoom) ?
			    self.getEndZoom : riotNullHandler;
     self.dataZoneMouseLeave = self.dataZoneMouseUp;
  
     // we assume that if self test is false
     // it is not necessary to redraw all the svg
     
     if (self.lastAlias != opts.alias ||
	 self.lastStartZoom != opts.startzoom ||
	 self.lastEndZoom != opts.endzoom
     ) {
       self.lastAlias = opts.alias;
       self.lastStartZoom = opts.startzoom;
       self.lastEndZoom = opts.endzoom;
       
       // Update Serie data
       self.series = opts.props.series.map(function (serie) {
	 serie.dataSerie = isDef(opts.datagraph[serie.dataName]) ?
			   opts.datagraph[serie.dataName] : Array();
	 return serie;
       });
       
       // Update scales
       var minY = maxY = minX = maxX = null;
       self.series.forEach(function (serie) {
	 serie.dataSerie.forEach(function (dataElt) {
	   if (isNotDef(minY)) minY = dataElt.y;
	   else if (dataElt.y < minY) minY = dataElt.y;
	   if (isNotDef(maxY)) maxY = dataElt.y;
	   else if (dataElt.y > maxY) maxY = dataElt.y;
	   
	   if (isNotDef(minX)) minX = dataElt.period;
	   else if (dataElt.period < minX) minX = dataElt.period;
	   if (isNotDef(maxX)) maxX = dataElt.period;
	   else if (dataElt.period > maxX) maxX = dataElt.period;
	 });
       });
       self.scaleX = d3
	 .scaleLinear().domain([minX, maxX]).range([0, self.dataZoneW]);
       self.scaleY = d3
	 .scaleLinear().domain([minY, maxY]).range([self.dataZoneH, 0]);
       
       // Redraw axis
       var xAxis = d3.axisBottom(self.scaleX),
	   yAxis = d3.axisLeft(self.scaleY)
		     .tickFormat(d3.format(opts.props.format));
       d3.select(self.xAxis).call(xAxis);
       d3.select(self.yAxis).call(yAxis);
       
       // Redraw series
       var series = d3.select(self.dataZone)
		      .selectAll(".serie").data(self.series);
       
       var newSeries = series.enter().append("path").classed("serie", true)
			     .attr("fill", "none");
       
       series.exit().remove();
       
       series.merge(newSeries)
	     .attr("stroke", function (serie) { return serie.color })
	     .attr("d", function (serie) {
	       var line = d3
		 .line()
		 .x(function (dataElt) { return self.scaleX(dataElt.period) })
		 .y(function (dataElt) { return self.scaleY(dataElt.y) });
	       return line(serie.dataSerie);
	     });
     }
       
     // Redraw mouse on period and legends
     var dataPOPs = isDef(opts.pointsonperiods) ?
		    self.series.map(function (serie) {
		      var pt = opts.pointsonperiods[serie.dataName];
		      pt.color = serie.color;
		      return pt;
		  }) :
		  Array();
     var pops = d3.select(self.dataZone)
			  .selectAll(".periodPoint").data(dataPOPs);
     var newPops = pops.enter().append("circle")
		       .classed("periodPoint", true)
		       .attr("stroke", "black").attr("r", 3);
     pops.exit().remove();
     pops.merge(newPops).attr("transform", function (d) {
       return "translate(" + self.scaleX(d.period) + "," + self.scaleY(d.y) + ")";
     }).attr("fill", function (d) { return d.color });

     var dataLeg = isDef(opts.pointsonperiods) ?
		   Array({ y: dataPOPs[0].period }).concat(dataPOPs) :
		   Array();
     var legs = d3.select(self.legends).selectAll(".legend").data(dataLeg);
     legs.exit().select(".value").text("");
     legs.merge(legs.enter()).
	  select(".value").text(function (d) { return ": " + d.y });

     
     if(isDef(opts.selectendzoom)) {
       var periodX = Math.min(opts.selectstartzoom, opts.selectendzoom),
	   periodY = Math.max(opts.selectstartzoom, opts.selectendzoom);
       self.zoomZoneX = self.scaleX(periodX);
       self.zoomZoneW = self.scaleX(periodY) - self.zoomZoneX }
     else self.zoomZoneW = 0;
   });

   getMousePeriod (clientX) {
     var htmlPt = self.dataZone.createSVGPoint();
     htmlPt.x = clientX;
     var svgPt = htmlPt.matrixTransform(self.dataZone.getScreenCTM().inverse());
     var domain = self.scaleX.domain();
     return bounded(
       domain[0],
       Math.round(self.scaleX.invert(svgPt.x - self.dataZoneX)),
       domain[1]);
   }
   
   mouseOnGraph (e) {
     if (isDef(self.scaleX)) {
       opts.mouseonperiod(self.getMousePeriod(e.clientX));
     }
     e.preventUpdate = true;
   }

   getStartZoom (e) {
     if (isDef(self.scaleX)) {
       opts.setstartzoom(self.getMousePeriod(e.clientX));
     }
     e.preventUpdate = true;
   }

   getEndZoom (e) {
     if (isDef(self.scaleX)) {
       opts.setendzoom(self.getMousePeriod(e.clientX));
     }
     e.preventUpdate = true;
   }
  </script>
</d3chart>
