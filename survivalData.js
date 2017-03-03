define(['jquery', 'underscore', 'd3', 'nvd3', 'jstat'], function($, _ , d3, nv, jStat) {

		var Survival = function(elem, options) {
						this.elem = elem;
						this.$elem = $(elem.get(0));
						this.options = options;
						this.metadata = this.$elem.data('options');
		};


	Survival.prototype = {
		defaults: {
			radius : 0.35,
			animate: true,
			url :  '/api/collection/survival',
			opts : {_choose: null, _type : 'normal' , _what: null} ,
			num	:0,
			scoreArray: ["0","MktLåg" , "Låg", "Medel", "Hög", "MycketHög"],
			Limit: 10

		},
		init: function() {
			//console.log("metadata"  + JSON.stringify(this.metadata));
			// Create an object with {"template":"row-template"}
			
		
			
			this.config = $.extend({}, this.defaults, this.options, this.metadata);
			// Load in rownames
			this.childTable		= $('#money');
			this.moneyOutput = [] ;
			this.timeframe	= [];
			this.chart ;
			this.chartData;
			// Run loading
			this.run();
			
			return this;
		},
		
		
		
		
		getClosest : function( ) {
				var	self		= this,
					array		= arguments[0] !== undefined ?  arguments[0] : null,
					 target		= arguments[1] !== undefined ?  arguments[1] : null,
					 point		= _.findWhere(array, {"x" : target});
				/*x has to be visiable inside map*/
				function extract() {
					var arg	= arguments[0] !== undefined ? arguments[0]: null;
					var tuples = _.map(arg, function(val) {
									return [val, Math.abs(val.x - target)];
								});
						return target =  _.reduce(tuples, function(memo, val) {
									return (memo[1] < val[1]) ? memo : val;
								}, [-1, 999])[0];		
				};
				
						
					var outPut_1	= {};
					switch (true) {
						case (point !== undefined):
							return point;
							break;
						case (point === undefined && array[0].values !== undefined):
							/*rund credit data */
							self.config.scoreArray.forEach(function(d,id){
							var point	= array[id] !== undefined ?
										_.findWhere(array[id].values, {"x" : Number(target)}) : null ;
								switch (true) {
									case (point === null):
									return true;
									break;
									case (point === undefined):
									outPut_1[d]  	= extract(array[id].values);
									break;
									default:
										outPut_1[d]	=  point;
										return true;
									break;
								}
							
							
							}); // end of foreach
							
						break;	
						case (point === undefined && array[0].values === undefined):
								outPut_1 = 	extract(array);
						break;
					} // end of switch
					
					
				return outPut_1;
					
		},
		/*@argument Get data with considering time and the selection of against time
		 *@USAGE self.fetchData(<data>, <variable>)
		 */
		fetchData :	function (){
			var data		= arguments[0] !== undefined ?  arguments[0] : null,
				yName		= arguments[1] !== undefined ?  arguments[1] : 'surv',
				xName		= arguments[2] !== undefined ?  arguments[2] : 'time';
				
			var result = [];
			_.each( data, function(itm) {
				var time		= parseInt( itm[xName]) ;
				var yvar		= /(surv|upper|lower)/i.test(yName) ? parseFloat(itm[yName])*100 : parseFloat(itm[yName]);
				if ( time <= 200) {			
					result.push(
							{x : itm[xName], y : yvar }
						 )
				}
				});
				
				
				
				return _.size(result) > 0 ? result : null;
		},
		
		createLineChart : function( ){
			
			var dataSet	= arguments[0] !== undefined ? arguments[0] : null,
				name	= arguments[1] !== undefined ? arguments[1] : 'all',
				self	= this,
				id		= self.elem.get(0).id,
				_chart  = $("#" + id);
			
		
				if(_chart.children().length > 1)
				{
						//Animate remove
						_chart.children().fadeOut(400, function() {
							this.remove();
						});
						self.chart = false;
				  
					
				}

			
			
			nv.addGraph(function() {
				chart = nv.models.lineChart()
				.options({
				    duration: 300,
				    useInteractiveGuideline: true
				})
				.forceY([0,100])
				.margin({top: 30, right: 20, bottom: 50, left: 100})
                .showYAxis(true)        //Show the y-axis
                .showXAxis(true)
				.showLabels(true);
				
      
			chart.lines.dispatch.on('elementClick', function(e) {
				/*x = time, y = Money In, update table */
					var idx 		= _.size(e) > 1 ? j$.max(_.pluck(e, 'pointIndex')) : e[0].pointIndex,
						points		= self.getClosest(self.moneyOutput,  idx),
						updatevVars	= ['Day','Money In', 'Ratio paid (%)'],
						colNames	= _.pluck(self.childTable.find("thead th"), 'innerHTML'),
						idObject	= {};	
				
				updatevVars.forEach(function(d1, id1){		
					if (_.indexOf(colNames, d1) !== -1 ) {
						idObject[d1] = _.indexOf(colNames, d1);
					}
				});
				var thCount	 	= _.size(_.keys(points) ) > 2 ? _.size(_.keys(points) ) : 1;
					tdCount		= _.size(idObject),
					placement	= _.values(idObject),
					LastID		= _.last(placement) ,
					Values		= _.values(points),
					Range		= _.range(thCount);
				
				Range.forEach(function(n){
					var th1 		= self.childTable.children("tbody").children(`tr:nth(${n})`),
						tdValue		= Number(th1.children(`td:nth-child(${LastID})`).html().replace(/\s+/, "")),
						tmpPoint	= _.size(Range) > 1 ? Values[n] : Values,
						Count		= 0;
					_.map(idObject, function(id, name){
						var	tmpPoint1	= _.values(tmpPoint),
							insertPoint	= tmpPoint1[Count] !== undefined ? tmpPoint1[Count] :
											(tmpPoint1[Count - 1]/tdValue*100).toFixed(1);
						th1.children(`td:nth-child(${id + 1})`).html(insertPoint);
						++Count;
					})
					
				});
				
			});
	
			chart.xAxis     //Chart x-axis settings
				.axisLabel('Number of days to payment')
				.ticks(10)
				.tickFormat(d3.format(',r'));

			chart.yAxis     //Chart y-axis settings
				.axisLabel('Probability')
				.tickFormat(d3.format('.0f'));


			chartData =  d3.select("#" + id)
			        .append("svg")
					.attr("width", '100%')
					.attr("height", '400px')
					.datum(dataSet);
					
			chartData.transition().duration(500).call(chart);		
				
			var what 	= /\S+\.\S+/.test(name) ? 'merchant' : 'operator';
			var name1 = "Probability that a person pays their invoice within a certain time frame [" + what + ": " +  name + "]" ;			

			var $svg = $("#" + id +  " svg" );
			$svg.parent().append(
				"<div class='chart-title'><em>" 
				+ name1  + "</em></div>");
			//Update the chart when window resizes.
			nv.utils.windowResize(function() { chart.update() });
			return chart;
			}	);
		},
		
	
		updateTable	: function(){
				var self 		= this,
					_type		= self.config.opts._type;
					colName		= /^(normal)$/i.test(_type) ?
									['Day', 'Money In', 'Amount paid', 'Ratio paid (%)'] :
									['Score', 'Day', 'Money In', 'Amount paid', 'Ratio paid (%)'] ,
					toolTip1	= "Click on line point in the graph to view money in at the clicked time",
					toolTip2	= "totalAmount paid to collection until requested time (see 'Day' column)",
					toolTip3	= "Total amount paid in for the whole analyzed time frame (see date above)",
					toolTip4	= "Score intervall as provided by the scoring agency",
					sourceData	= self.extractData( /^(normal)$/i.test(_type) ? null : _type ),
					totalAmount = sourceData[2] !== undefined ? sourceData[2] : j$.sum(_.pluck(sourceData, "2")) ;

					
					
				if ( self.childTable.children().length > 1) {
					self.childTable.children().remove();
				}
				var tableCaption	= $('<caption>')
										.addClass("captiontimeframe")
										.html("<b>" + self.timeframe[0] + " : " + self.timeframe[1] + "</b>")
										.appendTo(self.childTable);
				var tHead			= $('<thead>').appendTo(self.childTable);
				var row = $("<tr/>");
				$.each(colName, function(colindex, c) {
					 
					 switch (true) {
                        case (/^(day)$/i.test(c)):
                            var Obj       = toolTip1 ;
                        break;
                        case (/^(money in)$/i.test(c)):
                            var Obj       = toolTip2 ;
                        break;
                        case (/^(amount paid)$/i.test(c)):
                             var Obj       = toolTip3 + " total amount " +  totalAmount + " SEK" ;
                        break;
						case (/^(score)$/i.test(c)):
                             var Obj       = toolTip4 ;
                        break;
                        default:
                            var Obj       = null ;    
                    } // end of switch
					if (null !== Obj) {
						
						var message = {"data-container": "body",
													"data-toggle":"tooltip"};
							message["data-original-title"] = 	Obj.toString();					
						row.append($("<th/>")			
							.attr(message)
							.text(c));	
					} else {
						row.append($("<th/>").text(c));	
					}
					
					
				});
				row.appendTo(tHead);
				var tBody			= $('<tbody>').prependTo(self.childTable);
				
				var row = $("<tr/>");
				if (/^(normal)$/i.test(_type) ) {
					_.map(sourceData, function(index, c){
						row.append($("<td/>").html(index));
					});				
					row.appendTo(tBody);
				} else {
					self.config.scoreArray.forEach( function(d,idx){
						var row = $("<tr/>");
						row.append($("<td/>").html(d));
						_.map(sourceData[d], function(index, c){
							row.append($("<td/>").html(index));
						});		
						row.appendTo(tBody);			// c = scoreInteval, index array
					});

				}
				
			//childTable.children("tbody").children("tr").children("td:nth-child(3)").html('10019 ')	
		},
		
		extractData : function( ){
			var	self		= this,	
				num			= arguments[0] !== undefined ?  arguments[0] : null
				outPut		= {};
			
			if ( null === num ) {
				var Last 	= _.last(self.moneyOutput).y,
					First	= _.first(self.moneyOutput);
				return 	[	First.x,
							First.y,
							Last,
							First.y/Last !== undefined ? (First.y/Last*100).toFixed(1) : 0]
			} else {
				self.config.scoreArray.forEach( function(d, id){
					var array1		= _.find(self.moneyOutput, {"key": d});
					if (array1 === undefined) {
						return true;
					} 
					var	Last		= _.last(array1.values).y,
						First		= _.first(array1.values);
					outPut[d] 		= [	First.x,
										First.y,
										Last,
										First.y/Last !== undefined ? (First.y/Last*100).toFixed(1) : 0];
				});
				return outPut;
			}	
				
		},
		
		/*self.fetchKredit(sourceData['money'], 'moneyIn', 'DaysInInkasso')
		 *
		 */
		fetchKredit	: function(){
			var	self		= this,
				dataDT		= arguments[0] !== undefined ?  arguments[0] : null,
				scoreVar	= _.size(_.intersection(_.keys(dataDT[0]),  ["score"])) > 0 ?  "score" : "scoreInterval" ,
				scorce 		= dataDT !== null ? _.intersection(self.config.scoreArray,
															_.uniq(_.pluck(dataDT, [scoreVar] ))) : null  ,
				colors		= d3.scale.category10(),
				output		= [],
				rowCount	= 0,
				yName		= arguments[1] !== undefined ?  arguments[1] : 'surv', /*kumulativ*/
				xName		= arguments[2] !== undefined ?  arguments[2] : 'time'; /*DaysInInkasso*/
		
				scorce.forEach(function(d,id){
					var dataArray		= _.where(dataDT, {[scoreVar] : d} ),
						result			= [];
					_.each( dataArray, function(itm) {
						var time		= parseInt( itm[xName]) ;
						var yvar		= /^(scoreinterval)$/i.test(scoreVar) ?
														parseFloat(itm[yName]) :
														parseFloat(itm[yName])*100 ;
						if ( time <= 200) {			
							result.push(
									{x : itm[xName], y : yvar }
							 )
						}
					});
					var searchRest		= /^(scoreinterval)$/i.test(scoreVar) ?
												{values : result, key : d } :
												{values : result, key : d, color : colors(d) };
					output.push(searchRest);
			});
		
			return 	output;
		},
		run: function(  ){
            var self 		= this;
            var options      = (arguments[0] !== undefined) ? arguments[0] : null;
            if ( null !==  options)
			{
				this.config		= $.extend(this.config, options);
            }
            
        
        
			$.when( $.post(self.config.url, self.config.opts) )
				.done( function(data){
                     var  	data1           = _.size(data.SurvivalTable[0]) > 0 ? data.SurvivalTable[0] : 'error',
                            date            = data1.date !== undefined ? data1.date  : null,
                            sourceData      = data1.sourceData !== undefined ? JSON.parse(data1.sourceData) : null;
							
                if( null === sourceData || /error/.test(data1 ))
                {
                    throw 'Error source data';
					
                }
				
				if (data1.operatorId !== undefined)
				{
					var 	operator = data1.siteId !== 'NULL' ? data1.siteId : data1.operatorId;
				}
				
				
			
				if ( /^(kredit)$/i.test(self.config.opts._type))
				{
					self.moneyOutput		= self.fetchKredit(sourceData['money'], 'kumulativ', 'DaysInInkasso') ;
					var output			 	= self.fetchKredit( sourceData.data) ;
				} else {
					self.moneyOutput	= self.fetchData( sourceData['money'], 'kumulativ', 'DaysInInkasso');
					self.timeframe		=  sourceData.timeframe;
					var surv 			= self.fetchData(sourceData.data, "surv"),
						lower 			= self.fetchData(sourceData.data, "lower"),
						upper 			= self.fetchData(sourceData.data, "upper");
					
			
			
					var output = [ {values : lower, key : "Lower", color: '#ff7f0e'},
									{values : surv, key : "Payment",  color: '#2ca02c'},
									{ values: upper, key : 'Upper', color: '#7777ff'}];
				}
				
				self.createLineChart(output, operator );
				self.updateTable();
			    }).fail(function(xhr, status, error){
                    self.loading( 'empty');
                    $('.search-button').html("Search");
                    return null;
                } );		
		}
	}	 // 	Survival.prototype
	
	
		
	
	Survival.defaults = Survival.prototype.defaults;
	/* @argument options if empty 
	 * 
	 */ 
	$.fn.survivalData = function(options) {
		var plugin = $(this).data('survivalData');
		// first time will be undefined
		if (plugin == undefined) {			
			plugin = new Survival(this, options).init();
			$(this).data('survivalData', plugin);
			return plugin;
		}
        
       
		// Check if the argument given in  is valid and return a Function
		if($.isFunction(Survival.prototype[options])){
			/* will always be a single since its decided by the caller
			 */
			var args = Array.prototype.slice.call(arguments);
		
            args.shift();
			// call of loading on each argument inside plugin 
            return Survival.prototype[options].apply(plugin, args);
        }

		return this;
	}; // end of jQuery.prototype
})