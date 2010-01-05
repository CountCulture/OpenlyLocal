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

		$('a.delete_parent_div').live("click", function(event){
			  $(this).parents('div:first').remove();
				event.preventDefault();					
		});
		
		$('a.add_more_attributes').click(function(event){
				$('.item_attribute:last').clone().appendTo("#parser_attribute_parser");
				event.preventDefault();					
		});
		
		$('.graphed_datapoints img').click(function(event){
				$(this).parents('div.graph').hide();
				$(this).parents('.graphed_datapoints').removeClass('graphed_datapoints');
				event.preventDefault();					
		});
		
});