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

		$('a.toggle_visibility').click(function(event){
			  $(this).closest('div').children('.toggle').toggle();
				event.preventDefault();					
		});

		$('a.add_new_scraper').click(function(event){
			var resultModels = ['Committee', 'Member', 'Meeting', 'Ward', 'PlanningApplication'];
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
		
		$('dd.company_number a').getCompanyData();
		
		$('a.process_scraper.button').click(function(event){
		  var link = $(this);
		  $.post(this.href, function(data) {
		    var parent = link.parent();
        link.replaceWith("<span class='alert button'>queued for processing</span>")
        parent.children('.alert.button').fadeOut(5000);
      });
			event.preventDefault();					
		});
		$('input.process_scraper').parents('form').submit(function() {
		  event.preventDefault();
		  form = $( this );
		  $.post(form.attr('action') + '/scrape', function(data) {
       form.html("<span class='alert button'>queued for processing</span>")
       form.fadeOut(5000);
      });
    });

    /* Planning alerts */
    /*
    // @todo PostGIS: uncomment after switch
    $('#alert_subscriber_postcode_text,#new_alert_subscriber input:radio').change(function (event) {
      var $header = $('#planning-alerts-preview h2'),
          $list = $('#planning_applications'),
          postcode = $('#alert_subscriber_postcode_text').val(),
          distance = $('#new_alert_subscriber input:radio:checked').val();

      $header.empty();
      $list.empty();

      if (postcode) {
        if (distance === undefined) {
          distance = 0.2;
        }

        $.ajax({
          url: '/planning_applications.json?postcode=' + encodeURIComponent(postcode) + '&distance=' + distance,
          dataType: 'json',
          success: function (data) {
            $header.text('Recent applications within ' + (distance * 1000) + ' m of ' + postcode);
            $.each(data.planning_applications, function (i, x) {
              $list.append(
                '<div class="planning_application">' +
                  '<strong class="description">' +
                    '<a href="' + x.openlylocal_url + '" class="planning_application_link">' + x.description + '</a>' +
                  '</strong> ' +
                  '<span class="address">' + x.address + '</span> ' +
                  '<a href="' + x.url + '" class="official_page external url">official page</a>' +
                '</div>'
              );
            });
          },
          error: function (jqXHR) {
            $header.text(jqXHR.responseText);
          }
        });
      }
    });
    */
});

// Map Geography Utility functions - see http://www.movable-type.co.uk/scripts/latlong.html#destPoint  
function getDestlatLng(latLng, bearing, distance) {
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
 var sw = getDestlatLng(centrePt, 225, hypotenuse);
 var ne = getDestlatLng(centrePt, 45, hypotenuse);
 return new GLatLngBounds(sw, ne);
}

function createMarker(obj, map, caption) {
  var icon = new GIcon(G_DEFAULT_ICON);
  var iconUrl = "http://chart.apis.google.com/chart?cht=mm&chs=20x20&chco=6699AAFF,336699FF,336699FF&ext=.png";
  icon.image = iconUrl;
  icon.iconSize = new GSize(20, 20);
  icon.shadowSize = new GSize(32, 20);
  icon.iconAnchor = new GPoint(10, 20);
  icon.infoWindowAnchor = new GPoint(10, 1);
  icon.printImage = iconUrl + "&chof=gif";
  icon.mozPrintImage = iconUrl + "&chf=bg,s,ECECD8" + "&chof=gif";

  var latlng = new GLatLng(obj.lat, obj.lng);
  var marker = new GMarker(latlng, { icon:icon });
  GEvent.addListener(marker,"click", function() {
    map.openInfoWindowHtml(latlng, caption, {maxWidth:200});
  });
  return marker;
}

function planningAppCaption (pa) {
  var infoCaption = "<div class='caption planning_application'><h4><a href='/planning_applications/" + pa.id + "'>" + pa.uid + "</a>";
  infoCaption += (pa.start_date ? ", <span class='date'>" + pa.start_date + "</span>" : '') + "</h4><div class='address'>" + pa.address + "</div>";
  infoCaption += (pa.description ? ("<p>" + pa.description.slice(0,90) + "...") : '<p>');
  infoCaption += "<a href='/planning_applications/" + pa.id + " class='more_info'>more info</a></p></div>";
  return infoCaption;
}

function populateCompanyData(companyData) {
  var company = companyData.company;
  var dlData = {};
  var dlString = '';
  dlData['status'] = company.current_status;
  dlData['company_type'] = company.company_type;
  dlData['registered_address'] = company.registered_address_in_full;
  dlData['incorporation_date'] = company.incorporation_date;
  dlData['dissolution_date'] = company.dissolution_date;
  // if (company.data&&company.data.most_recent) {
  //   var data = $.map(company.data.most_recent, function(d) {
  //     var cd = linkTo(d.datum.title, d.datum.opencorporates_url);
  //     if (d.datum.description) {cd = cd + ' (' + d.datum.description + ')';};
  //     return cd;
  //   } );
  //   dlData['latest_data'] = data.join(', ');
  // };
  if (company.previous_names) {
    var previous_names = $.map(company.previous_names, function(pn) {
      return pn.company_name + ' (' + pn.con_date + ')';
    } );
    dlData['previous_names'] = previous_names.join(', ');
  };
  if (company.corporate_groupings) {
    var corporate_groupings = $.map(company.corporate_groupings, function(cg) {
      return linkTo(cg.corporate_grouping.name, cg.corporate_grouping.opencorporates_url);
    } );
    dlData['corporate_grouping'] = corporate_groupings.join(', ');
  };
  if (company.filings) {
    var filings = $.map(company.filings.slice(0,2), function(f) {
      return '<span class="date">' + f.filing.date + '</span> ' + linkTo(f.filing.title, f.filing.opencorporates_url);
    } );
    dlData['latest_filings'] = filings.join(', ');
  };
  $.each(dlData, function(k,v) { 
    dlString = dlString + buildDlEl(k,v);
    } );
  $('dl.attributes').append(dlString);
  $('.ajax_fetcher').fadeOut();     
}
function buildDlEl(k, v) {
  return (v ? '<dt>' + toTitleCase(k) + '</dt><dd class="'+ k + '">' + v + '</dd>' : '');
}
function toTitleCase(str)
{
   return str.replace('_',' ').replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
}
function linkTo(txt,url) {
  return '<a href="'+ url + '">' + txt + '</a>'
}

jQuery.fn.getCompanyData = function () {
  var el = $(this)[0];
  if (el) {
	  $('dl.attributes').before("<div class='ajax_fetcher'>Fetching data from OpenCorporates</div>");
	  var oc_url = $(this)[0]['href'] + '.json?callback=?';
    $.getJSON(oc_url, function(data) { populateCompanyData(data) });
  };
}

