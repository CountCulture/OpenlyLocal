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

NessSelectedTopics = { :demographics => (47..62).to_a, # pecentage population 20-24, 30-44, 45-59
                       :economic => [5023, 2028],
                       :religion => (2006..2014).to_a, # count of religions
                       :misc => [627, 63, 1920] } # population, mean age of population, number of dwellings
DisplayDatapoints = { :religion => :graph }

# Measurement UIDs. These are used by Ness, but we can also use as universal way of formatting data
Muids = { 1 => ['Count'],
          2 => ['Percentage', "%.1f%"],
          9 => ['Pounds Sterling', "£%d"],
          14 => ['Years', "%.1f"],
          41 => ['Square metres (thousands)'],
          100 => ['Yes/No']
          }
          
Regions = { 'North East'                => ['A', 276700],
            'North West'                => ['B', 276701],
            'Yorkshire and The Humber'  => ['D', 276702],
            'East Midlands'             => ['E', 276703],
            'West Midlands'             => ['F', 276704],
            'East of England'           => ['G', 276705],
            'London'                    => ['H', 276706],
            'South East'                => ['J', 276707],
            'South West'                => ['K', 276708]
}

# NESS_IDS = {'England' => 276693, 'Northern Ireland' => 276696, 'Scotland' => 276694, 'Wales' => 276695}
AllowedCountries = ['England', 'Northern Ireland', 'Scotland', 'Wales']