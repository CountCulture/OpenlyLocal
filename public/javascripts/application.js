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
			extraParams: {
				council_id: function() { return $("#council_id").val(); },
				q: '',
				minChars: 2,
				term: function() { return $("#term").val();}
			},
      mustMatch: true
  }).result(function(event, item) {
			  location.href = item.url;
			});;



});