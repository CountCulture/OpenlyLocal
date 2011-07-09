# List of parties we have info for
# Each element in the array is an array of the form:
# # [[main_name, preferred abbreviation, other, names], colour, wikipedia/dbpedia id]

PARTIES = [
  [ [ "Conservative", "Con", "Conservatives", "Cons", "CONSERVATIVE" ], "0281AA", "Conservative_Party_(UK)" ],
  [ [ "Labour", "Lab", "LABOUR"], "AA0000", "Labour_Party_(UK)" ],
  [ [ "Labour & Cooperative", "Labour Co-operative", "Labour Co-op", "Lab Co-op"], "AA0000", "Labour_Co-operative" ],
  [ [ "Liberal Democrat", "LibDem", "Liberal Democrats", "Liberal democrats", "LDem", "Lib Dem", "Lib", "LIBERAL DEMOCRATS" ], "F3A63C", "Liberal_Democrats" ],
  [ [ "Plaid Cymru", "PLAID CYMRU" ], "FDC00F", "Plaid_Cymru" ],
  [ [ "Scottish National", "SNP" ], "FAE93E", "Scottish_National_Party" ],
  [ [ "Green", "Green", "Greens", "GREEN" ], "73A533" ],
  [ [ "British National Party", "BNP" ], nil, "British_National_Party" ]
  ]

DefaultDomain = "openlylocal.com"
BlogFeedUrl = "http://countculture.wordpress.com/category/openlylocal/feed/"

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

Licences = {'CC0' => ['Creative Commons CC0 Universal', 'http://creativecommons.org/publicdomain/zero/1.0/', 'open'],
            'CCBY30' => ['Creative Commons By Attribution 3.0', 'http://creativecommons.org/licenses/by/3.0/', 'open'],
            'CCBYSA20' => ['Creative Commons Attribution-Share Alike 2.0', 'http://creativecommons.org/licenses/by-sa/2.0/', 'open'],
            'CCBYSA30' => ['Creative Commons Attribution-Share Alike 3.0 Unported', 'http://creativecommons.org/licenses/by-sa/3.0/', 'open'],
            'CCBYNC30' => ['Creative Commons Attribution-Noncommercial 3.0', 'http://creativecommons.org/licenses/by-nc/3.0/', 'semi_open'],
            'CCBYNCSA30' => ['Creative Commons Attribution-Noncommercial-Share Alike 3.0', 'http://creativecommons.org/licenses/by-nc-sa/3.0/', 'semi_open'],
            'DATAGOVUK' => ['Open Government Licence', 'http://www.nationalarchives.gov.uk/doc/open-government-licence/', 'open'],
            'ADHOCNC' => ['Ad Hoc Attribution-Noncommercial', nil, 'semi_open'],
            'ADHOCBY' => ['Ad Hoc Attribution only', nil, 'open']
            }