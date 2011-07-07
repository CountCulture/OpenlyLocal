var EARTH_RADIUS = 3963.19; //in miles
var circle;

// With help from http://blog.schuager.com/2008/09/jquery-autocomplete-json-apsnet-mvc.html and http://1300grams.com/2009/08/17/jquery-autocomplete-with-json-jsonp-support-and-overriding-the-default-search-parameter-q/
$(document).ready( function() {
  $('.live_search').autocomplete("/services.json", {
      dataType: 'json',
      parse: function(data) {
          var rows = new Array();
          for(var i=0; i<data.length; i++){
              rows[i] = { data:data[i].service, value:data[i].service.title, result:data[i].service.title };
          }
          return rows;
      },
      formatItem: function(row, i, n) {
          return '<a href="'+ row.url + '" class="external">' + row.title + '</a>';
      },
      width: 300,
			cacheLength: 400,
			minChars: 2,
			extraParams: {
				council_id: function() { return $("#council_id").val(); },
				q: '',
				term: function() { return $("#term").val();}
			},
      mustMatch: true
  }).result(function(event, item) {
			  location.href = item.url;
			});

		$('a.show_possible_scrapers').click(function(event){
			  $(this).parents('div.council').children('.possible_scrapers').toggle();
				event.preventDefault();					
		});

		$('a.add_new_scraper').click(function(event){
			var resultModels = ['Committee', 'Member', 'Meeting', 'Ward'];
			var scraperList = '';
			var cDiv = $(this).parents('div.council')[0];
			var cId = cDiv.id.replace('council_','');
			for (var i=0; i < resultModels.length; i++) {
				scraperList += '<li><a href="/scrapers/new?type=ItemScraper&result_model=' + resultModels[i]+ '&council_id='+ cId + '">Add ' + resultModels[i] + ' ItemScraper for this council</a></li>';
				scraperList += '<li><a href="/scrapers/new?type=InfoScraper&result_model=' + resultModels[i]+ '&council_id='+ cId + '">Add ' + resultModels[i] + ' InfoScraper for this council</a></li>';
			};
			scraperList += '<li><a href="/scrapers/new?type=CsvScraper&council_id='+ cId + '">Add CsvScraper for this council</a></li>';
			$(cDiv).find('ul').append(scraperList);
		  event.preventDefault();					
		});
		
		$('a.delete_parent_div').live("click", function(event){
			  $(this).parents('div:first').remove();
				event.preventDefault();					
		});
		
		$('a.add_more_attributes').click(function(event){
				$('.item_attribute:last').clone().appendTo("#parser_attribute_parser");
				event.preventDefault();					
		});
		
		$('table#payer_breakdown').click(function(event){
			$(this).find('tr.element').toggle();
			$(this).find('td span.description').toggle();
		});
		
		$('.graphed_datapoints img').click(function(event){
				$(this).parents('div.graph').hide();
				$(this).parents('.graphed_datapoints').removeClass('graphed_datapoints');
				event.preventDefault();					
		});
		
		$('dd.company_number a').click(function(event){
	    $.getJSON($(this).attr("href")+'.json?callback=?', function(data) {populateCompanyData(data)});					
			event.preventDefault();					
		});
		
});

// Map Geography Utility functions - see http://www.movable-type.co.uk/scripts/latlong.html#destPoint  
function getDestLatLng(latLng, bearing, distance) {
 var lat1 = latLng.latRadians();
 var lng1 = latLng.lngRadians();
 var brng = bearing*Math.PI/180;
 var dDivR = distance/EARTH_RADIUS;
 var lat2 = Math.asin( Math.sin(lat1)*Math.cos(dDivR) + Math.cos(lat1)*Math.sin(dDivR)*Math.cos(brng) );
 var lng2 = lng1 + Math.atan2(Math.sin(brng)*Math.sin(dDivR)*Math.cos(lat1), Math.cos(dDivR)-Math.sin(lat1)*Math.sin(lat2));
 return new GLatLng(lat2/ Math.PI * 180, lng2/ Math.PI * 180);
}

function drawCircle(curr_map, centrePt, rangeValue) {
 if(circle){curr_map.removeOverlay(circle)};
 var boundaries = getBoundaries(centrePt, rangeValue);
 circle = new GGroundOverlay("http://openlylocal.com/images/circle_overlay.png", boundaries);
 // console.info(circle); don't enable this in production
 curr_map.addOverlay(circle);
}

function getBoundaries(centrePt, radius) {
 var hypotenuse = Math.sqrt(2 * radius * radius);
 var sw = getDestLatLng(centrePt, 225, hypotenuse);
 var ne = getDestLatLng(centrePt, 45, hypotenuse);
 return new GLatLngBounds(sw, ne);
}

function populateCompanyData(companyData) {
  var company = companyData.company;
  var dlData = {};
  dlData['status'] = company.current_status;
  dlData['registered_address'] = company.registered_address_in_full;
  var previous_names = company.previous_names;
  // dlData ['dissolution_date'] = company.dissolution_date
  // var attribs = ['status','registered_address','dissolution_date']
  var dlString = '';
  // $.each(dlData, function(k,v) { 
  //   dlString = dlString + buildDlElement(k,v);
  //   } )
  // $('dl#main_attributes').append(dlString);
  // alert(registered_address);
}

function buildDlElement (k, v) {
  '<dt>' + k + '</dt><dd class="'+ k + '">' + v + '</dd>'
}