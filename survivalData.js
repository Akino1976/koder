define(['jquery', 'underscore', 'handlebars', 'd3', 'nvd3'], function($, _ ,Handlebars, d3, nv) {

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
			// Run loading
			this.run();
			
			return this;
		},
		
		/*@argument Get data with considering time and the selection of against time
		 *@USAGE self.fetchData(<data>, <variable>)
		 */
		fetchData :	function (){
			var data		= arguments[0] !== undefined ?  arguments[0] : null,
				yName		= arguments[1] !== undefined ?  arguments[1] : 'surv';
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
			
				var self = this;
        
				if(_chart.children().length > 1)
				{
						//Animate remove
						_chart.children().fadeOut(400, function() {
							this.remove();
						});
						self.chart = false;
				  
					
				}

			
			
			nv.addGraph(function() {
			var chart = nv.models.lineChart()
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
					var idx 	= e[0].pointIndex,
						points	= _.findWhere(self.moneyOutput, {x : idx});
						
					
				self.childTable.children("tbody").children("tr").children("td:nth-child(1)").html(points.x);
				self.childTable.children("tbody").children("tr").children("td:nth-child(2)").html(points.y);
				self.childTable.children("tbody")
					.children("tr")
					.children("td:nth-child(4)")
					.html((points.y/_.last(self.moneyOutput).y*100).toFixed(1));
			});
	
			chart.xAxis     //Chart x-axis settings
				.axisLabel('Number of days to payment')
				.ticks(10)
				.tickFormat(d3.format(',r'));

			chart.yAxis     //Chart y-axis settings
				.axisLabel('Probability')
				.tickFormat(d3.format('.0f'));


			 d3.select("#" + id)
			        .append("svg")
					.attr("width", '100%')
					.attr("height", '400px')
					.datum(dataSet)
					.call(chart);
				
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
					colName		= ['Day', 'Money In', 'Amount paid', 'Ratio paid (%)'],
					toolTip1	= {"data-container": "body",
									"data-toggle":"tooltip",
									"data-original-title" :"Click on line point in the graph to view money in at the clicked time"
					},
					toolTip2	= {"data-container": "body",
									"data-toggle":"tooltip",
									"data-original-title" :"totalAmount paid to collection until requested time (see 'Day' column)"
					},
					toolTip3	= {"data-container": "body",
									"data-toggle":"tooltip",
									"data-original-title" :"Total amount paid in for the whole analyzed time frame (see date above)"
					}
					
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
                             var Obj       = toolTip3 ;
                        break;    
                        default:
                            var Obj       = null ;    
                    } // end of switch
					if (null !== Obj) {
						row.append($("<th/>")
							.attr(Obj  ).text(c));	
					} else {
						row.append($("<th/>").text(c));	
					}
					
					
				});
				row.appendTo(tHead);
				var tBody			= $('<tbody>').prependTo(self.childTable);
				var Last 	= _.last(self.moneyOutput).y,
					First	= _.first(self.moneyOutput); 
				var row = $("<tr/>");
				_.map([	First.x,
						First.y,
						Last,
						First.y/Last !== undefined ? (First.y/Last*100).toFixed(1) : 0], function(index, c){
					row.append($("<td/>").html(index));
				});				
				row.appendTo(tBody);
				
					
			//childTable.children("tbody").children("tr").children("td:nth-child(3)").html('10019 ')	
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
				
				self.moneyOutput	= self.fetchData( sourceData['money'], 'kumulativ', 'DaysInInkasso');
				self.timeframe		=  sourceData.timeframe;
				
				var surv 			= self.fetchData(sourceData.data, "surv"),
					lower 			= self.fetchData(sourceData.data, "lower"),
					upper 			= self.fetchData(sourceData.data, "upper");
					
			
			
				var output = [ {values : lower, key : "Lower", color: '#ff7f0e'},
								{values : surv, key : "Payment",  color: '#2ca02c'},
								{ values: upper, key : 'Upper', color: '#7777ff'}];
				
				self.createLineChart(output,operator );
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