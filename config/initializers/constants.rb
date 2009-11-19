# List of parties we have info for
# Each element in the array is an array of the form:
# # [[main_name, preferred abbreviation, other, names], colour]

PARTIES = [
  [ [ "Conservative", "Con", "Conservatives", "Cons", "CONSERVATIVE" ], "0281AA" ],
  [ [ "Labour", "Lab", "LABOUR"], "AA0000" ],
  [ [ "Liberal Democrat", "LibDem", "Liberal Democrats", "Liberal democrats", "LDem", "Lib Dem", "Lib", "LIBERAL DEMOCRATS" ], "F3A63C" ],
  [ [ "Plaid Cymru", "PLAID CYMRU" ], "FDC00F"],
  [ [ "Scottish National", "SNP" ], "FAE93E"],
  [ [ "Green", "Green", "Greens", "GREEN" ], "73A533" ]
  ]
  
DefaultDomain = "openlylocal.com"
BlogFeedUrl = "http://countculture.wordpress.com/feed/"

ResourceRepresentations = { :rdf => "application/rdf+xml", 
                            :json  => "application/json",
                            :xml  => "application/xml",
                            :html => "text/html" }