<scamelclient>
  <header>
    <h1>Scamel</h1>
    <span>loaded {currentLoad} read {currentRead}
      displayed {endZoom - startZoom}</span>
    <nav>
      <button onclick={togglePlay}
	      disabled={currentRead == currentLoad}
      >{play ? "Pause" : "Play"} </button>
      <button onclick={clickEnd}
	      disabled={currentRead == currentLoad} >End</button>
      <button onclick={unZoom}
	      disabled={currentRead == endZoom && startZoom == 0}
      >UnZoom</button>
      <virtual each={panels} >
	<input type="radio" name="panel" checked={name == currentPanel.name}
	id={"panel-radio-" + name} onclick={changePanel(this)} />
	<label for={"panel-radio-" + name} >{name}</label>
      </virtual>
    </nav>
  </header>
  <div class="charts" >
    <d3chart each={val,index in currentPanel.charts} alias={val}
	     props={charts[val]} datagraph={dataCut} play={play}
	     startzoom={startZoom} endzoom={endZoom}
	     selectstartzoom={selectStartZoom} selectendzoom={selectEndZoom}
	     setstartzoom={setStartZoom} setendzoom={setEndZoom}
	     pointsonperiods={pointsOnPeriods} mouseonperiod={mouseOnPeriod} />
  </div>
		
  <script>

   var self = this;
   
   // ===================================
   // ===== INIT
   // ===================================
   self.panels = Object.keys(opts.panels).map(function (name) {
     return {
       name: name,
       charts: opts.panels[name] }
   });
   self.currentPanel = self.panels[0]
   self.charts = {}
   Object.keys(opts.charts).forEach(function (alias) {
     var chart = opts.charts[alias];
     self.charts[alias] =  {
       name: chart.name,
       type: ifNotDef(chart.type, "xIsPeriods"),
       width: ifNotDef(chart.width, opts.chartDefault.width),
       height: ifNotDef(chart.height, opts.chartDefault.height),
       x: chart.x,
       format: ifNotDef(chart.axeYFormat, opts.chartDefault.format),
       series: chart.series.map(function (serie, index) { return {
	 name: ifNotDef(serie.name, "y-" + index),
	 color: ifNotDef(serie.color, "black"),
	 format: ifNotDef(serie.format, opts.chartDefault.format),
	 dataName: serie.dataName
       }})}
   });
   self.play = true;
   self.stoppedByUser = false;
   self.currentLoad = 0;
   self.currentRead = 0;
   self.startZoom = 0;
   self.endZoom = 0;
   self.selectStartZoom = null;
   self.selectEndZoom = null;
   //self.startZoomSelection = null;
   //self.endZoomSelection = null;
   self.dataCut = {};
   self.pointsOnPeriods = null;

   // ===================================
   // ===== UPDATE
   // ===================================

   var data = {};
   
   self.on("update", function () {
     Object.keys(data).forEach(function (dataName) {
       self.dataCut[dataName] = data[dataName].filter(function (elt) {
	 return isDef(elt) &&
		elt.period >= self.startZoom && elt.period <= self.endZoom
       })
     })
   });
   
   // Load data
   var load = (function () {
     var loading = false; // one loading at a time
     return function () {
       if (loading || self.currentLoad >= opts.maxLoad) return;
       loading = true;

       var url = opts.url + "?start=" +
		 self.currentLoad + "&nb=" + opts.nbPeriodsByLoad,
	   nextLoad = self.currentLoad + opts.nbPeriodsByLoad;
       
       $.getJSON(url, function (answer) {
	 if (isDef(answer.periodsNotReady)) {
	   c.log("periods not ready");
	   c.log(answer);
	 }
	 else {
	   if (self.currentLoad == 0) {
	     Object.keys(answer.periods[1]).map(function (dataName) {
	       data[dataName] = Array();
	     })};
	   Object.keys(data).map(function (dataName) {
	     for (var p = self.currentLoad + 1 ; p <= nextLoad ; p ++) {
	       data[dataName][p] = {
		 period: p, y: answer.periods[p][dataName] }}
	   });
	   self.currentLoad = nextLoad;
	   if (! self.play && ! self.stoppedByUser) self.play = true;
	   self.update() }
	 loading = false;
       }).fail(function(jqxhr, textStatus, error) {
	 var err = textStatus + ", " + error;
	 c.log( "Request Failed: " + err );
	 loading = false;
       });
     }
   }) ()
   load();
   setInterval(load, opts.loadInterval);

   // Read data
   read () {
     if (self.play) {
       if (self.currentLoad > self.currentRead) {
	 if (self.currentRead == self.endZoom) self.endZoom += 1;
	 self.currentRead += 1 }
       else if (self.currentLoad > 0) {
	 self.play = false;
	 self.stoppedByUser = false }
       self.update();
     }
   }
   self.read();
   setInterval(self.read, opts.readInterval);
   
   changePanel (panel) { return function (e) {
     self.currentPanel = panel;
   }}
     
   togglePlay (e) {
     if (self.play) {
       self.play = false;
       self.stoppedByUser = true }
     else self.play = true }

   clickEnd (e) {
     if (self.currentRead == self.endZoom) self.endZoom = self.currentLoad;
     self.currentRead = self.currentLoad }

   unZoom () { self.startZoom = 0 ; self.endZoom = self.currentRead }

   mouseOnPeriod (period) {
     if (isDef(period) && period <= self.currentLoad) {
       self.pointsOnPeriods = {};
       Object.keys(data).forEach(function (dataName) {
	 self.pointsOnPeriods[dataName] = data[dataName][period];
       });
       if (isDef(self.selectStartZoom)) self.selectEndZoom = period;
     }
     else {
       self.pointsOnPeriods = null;
       self.selectEndZoom = null;
     }
     if (! self.play) self.update();
   }

   setStartZoom (period) {
     if(isDef(period) && period <= self.currentLoad) {
       self.selectStartZoom = period;
       self.update() }
   }

   setEndZoom (period) {
     if(isDef(period) && period <= self.currentLoad) {
       self.startZoom = Math.min(self.selectStartZoom, period);
       self.endZoom = Math.max(self.selectStartZoom, period);
       self.selectStartZoom = null;
       self.selectEndZoom = null;
       self.update() }
   }
  </script>
</scamelclient>
