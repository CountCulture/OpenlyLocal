# List of parties we have info for
# Each element in the array is an array of the form:
# # [[main_name, preferred abbreviation, other, names], colour, wikipedia/dbpedia id]

PARTIES = [
  [ [ "Conservative", "Con", "Conservatives", "Cons", "CONSERVATIVE" ], "0281AA", "Conservative_Party_(UK)" ],
  [ [ "Labour", "Lab", "LABOUR"], "AA0000", "Labour_Party_(UK)" ],
  [ [ "Liberal Democrat", "LibDem", "Liberal Democrats", "Liberal democrats", "LDem", "Lib Dem", "Lib", "LIBERAL DEMOCRATS" ], "F3A63C", "Liberal_Democrats" ],
  [ [ "Plaid Cymru", "PLAID CYMRU" ], "FDC00F", "Plaid_Cymru" ],
  [ [ "Scottish National", "SNP" ], "FAE93E", "Scottish_National_Party" ],
  [ [ "Green", "Green", "Greens", "GREEN" ], "73A533" ],
  [ [ "British National Party", "BNP" ], nil, "British_National_Party" ]
  ]

DefaultDomain = "openlylocal.com"
BlogFeedUrl = "http://countculture.wordpress.com/feed/"

ResourceRepresentations = { :rdf => "application/rdf+xml",
                            :json  => "application/json",
                            :xml  => "application/xml",
                            :html => "text/html" }

GoogleGadgetAnalyticsId = "UA-9440277-2"

NessSelectedTopics = { :demographics => [54, 55,  56, 57 ], #pecentage population 20-24, 30-44, 45-59
                       :economic => [5023, 2028],
                       :religion => (2006..2014).to_a, #count of religions
                       :misc => [627, 63] } #population, mean age of population
