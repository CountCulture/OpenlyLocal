desc "Quick and dirty scraper to get basic info about councils from eGR page"
task :scrape_egr_for_councils => :environment do
  BASE_URL = "http://www.brent.gov.uk"
  require 'hpricot'
  require 'open-uri'
  puts "Please enter eGR url to be scraped for councils: "
  url = $stdin.gets.chomp
  puts "Please enter global values (e.g attrib1=val1, attrib2=val2): "
  default_values = $stdin.gets.chomp
  default_hash = default_values.blank? ? {} : Hash[*default_values.split(",").collect{|ap| ap.split("=")}.flatten]
  doc = Hpricot(open(url))
  error_urls = []
  council_data = doc.search("#viewZone tr")[1..-1]
  council_data.each do |council_datum|
    council_link = council_datum.at("a[@href*='egr.nsf/LAs']")
    short_title = council_link.inner_text
    egr_url = BASE_URL + council_link[:href]
    puts "About to scrape eGR page for #{short_title} (#{egr_url})"
    begin
      detailed_data = Hpricot(open(egr_url))
    rescue Exception => e
      puts "***** Problem getting data from #{egr_url}: #{e.inspect}"
      error_urls << egr_url
      next
    end
    values = detailed_data.search("#main tr")
    full_name = values.at("td[text()*='Full Name']").next_sibling.inner_text.strip
    council = Council.find(:first, :conditions => ["BINARY name = ? OR BINARY name LIKE ?", full_name, "#{short_title} %"]) || Council.new
    council.attributes = default_hash
    puts (council.new_record? ? "CREATED NEW COUNCIL " : "Found EXISTING council " ) + full_name
    council.authority_type ||= values.at("td[text()*='Type']").next_sibling.inner_text.strip
    council.country ||= values.at("td[text()*='Country']").next_sibling.inner_text.strip
    council.name ||= full_name
    council.telephone ||= values.at("td[text()*='Telephone']").next_sibling.inner_text.gsub(/\302\240/,'').strip
    council.url ||= values.at("td[text()*='Website']").next_sibling.inner_text.strip
    council.address ||= values.at("td[text()*='Address']").next_sibling.inner_text.strip
    council.ons_url ||= values.at("td[text()*='Nat Statistics']").next_sibling.at("a")[:href]
    council.wikipedia_url ||= values.at("td[text()*='Wikipedia']").next_sibling.inner_text.strip
    council.egr_id ||= values.at("td[text()*='eGR ID']").next_sibling.at("font").inner_text.strip
    council.snac_id ||= values.at("td[text()*='SNAC']").next_sibling.at("font").inner_text.strip
    begin
      council.save!
      p council.attributes, "____________"
    rescue Exception => e
      puts "Problem saving #{council.name}: #{e.message}"
      error_urls << egr_url
    end
  end
  puts "\n--------\nFinished processing #{council_data.size} authorities"
  puts "Problems with #{error_urls.size}:"
  error_urls.each { |e| puts e }
end

desc "Scrape WhatDoTheyKnow.com to get WDTK name"
task :scrape_wdtk_for_names => :environment do
  require 'hpricot'
  require 'open-uri'
  url = "http://www.whatdotheyknow.com/body/list/local_council"
  doc = Hpricot(open(url))
  wdtk_councils = doc.search("#content .body_listing span.head")
  Council.find(:all, :conditions => 'wdtk_name IS NULL').each do |council|
    wdtk_council = wdtk_councils.at("a[text()*='#{council.short_name}']")
    if wdtk_council
      wdtk_name = wdtk_council[:href].gsub('/body/', '')
      council.update_attribute(:wdtk_name, wdtk_name)
      puts "Added WDTK name (#{wdtk_name}) to #{council.name} record\n____________"
    else
      puts "Failed to find entry for #{council.name}"
    end
  end

end

desc "Scraper council urls to get feed_url from auto discovery tag"
task :scrape_councils_for_feeds => :environment do
  require 'hpricot'
  require 'open-uri'
  Council.find(:all, :conditions => 'feed_url IS NULL').each do |council|
    next if council.url.blank?
    puts "=======================\nChecking #{council.title} (#{council.url})"
    begin
      doc = Hpricot(open(council.url))
    feed_urls = doc.search("link[@type*='rss']").collect{|l| l[:href].match(/^http:/) ? l[:href] : (council.url + l[:href])}
    council.update_attribute(:feed_url, feed_urls.first) # just save first one for the moment
    puts "#{council.title} feeds: #{feed_urls.inspect}"
    rescue Exception, Timeout::Error => e
      puts "****** Exception raised: #{e.inspect}"
    end
  end

end

desc "Import ONS SNAC codes into Wards table"
task :import_ward_snac_ids => :environment do
  csv_file = ENV['FILE']
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/ons_data/#{csv_file}"), :headers => true).to_a
  rows[1..-1].group_by{|r| r[2]}.each do |council_snac_id, council_group| # group by council SNAC id
    next unless council = Council.find_by_snac_id(council_snac_id)
    if council.wards.empty?
      council_group.each do |ward_data|
        council.wards.create(:snac_id => ward_data[0], :name => ward_data[1])
        puts "Successfully added #{ward_data[1]} ward (#{ward_data[0]}) for #{council.name}"
      end
    else
      council_group.each do |ward_data|
        if ward = council.wards.find_by_name(ward_data[1])
          ward.snac_id.blank? ? ward.update_attribute(:snac_id, ward_data[0])&&puts("Successfully updated #{ward_data[1]} ward (#{ward_data[0]}) for #{council.name}") :
                                puts("SNAC id already set for #{ward_data[1]} ward (#{ward_data[0]}) for #{council.name}")
        else
          "ALERT: ward (#{ward_data[1]}) missing for #{council.name}"
        end
      end
    end
  end

end

desc "Enter missing Ward SNAC ids"
task :enter_missing_snac_ids => :environment do
  csv_file = ENV['FILE'] || "WD08_LAD08_EW_LU.csv"
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/ons_data/#{csv_file}"), :headers => true).to_a
  snac_codes = rows[1..-1].group_by{|r| r[2]} # group by council SNAC id

  Ward.find_all_by_snac_id(nil, :include => :council).each do |ward|
    next unless poss_snac_codes = snac_codes[ward.council.snac_id]
    puts "\n====================\n#{ward.name} (#{ward.council.name})\n"
    puts "Choose from:"
    poss_snac_codes.each_with_index do |sc, index|
      puts "#{index}) #{sc[1]} (#{sc[0]})"
    end
    puts "Please enter number of ward, or SNAC id (type q to quit n to skip this ward): "
    response = $stdin.gets.chomp
    next if response == "n"
    break if response == "q"
    if response == response.to_i.to_s # if we've been pass an integer rather than alphanumeric snac_id treat as index
      snac_id = poss_snac_codes[response.to_i].first
      if existing_ward = Ward.find_by_snac_id(snac_id)
        puts "There is already a Ward with that Snac code (id = #{existing_ward.id}). Do you want to update that record with the SNAC id and delete this one (y/n):"
        answer = $stdin.gets.chomp
        existing_ward.destroy if answer == "y"
      end
      ward.update_attribute(:snac_id, snac_id)
    else
      ward.update_attribute(:snac_id, response)
    end
  end
end

desc "Import Council Officers from CLG CSV file"
task :import_council_officers => :environment do
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/KeyContactscurrenttocurrent.csv"), :headers => true).to_a
  headings = rows.shift

  rows.each do |row| # group by council SNAC id
    next unless council = Council.find_by_snac_id(row[1])
    council.officers.delete_all # clear current officers
    curr_officers = []
    headings[2..-2].each_with_index do |position, i|
      next if row[2+i].blank?
      names = row[2+i].split(",") # sometimes more than one name per office
      names.each do |name|
        curr_officers << officer = council.officers.create(:position => position.sub(/ Current$/, ''), :full_name => name)
        puts "#{officer.full_name}, #{position} for #{council.name}"
      end
    end
  end

end

desc "Enter missing Council LDG ids"
task :enter_missing_ldg_ids => :environment do

  Council.all(nil, :conditions => "ldg_id IS NULL AND (country='England' OR country='Wales')").each do |council|
    puts "\n====================\n#{council.name} (#{council.authority_type})\n"
    puts "Please enter LDG id (type q to quit n to skip this council): "
    response = $stdin.gets.chomp
    next if response == "n"
    break if response == "q"
    council.update_attribute(:ldg_id, response)
  end
end

desc "Import OS Ids from SPARQL endpoint"
task :import_os_ids => :environment do
  require 'hpricot'
  require 'open-uri'

  areas = { Ward => %w(UnitaryAuthorityWard DistrictWard LondonBoroughWard), Council => %w(Borough District County) }
  base_url = "http://api.talis.com/stores/ordnance-survey/services/sparql?query="
  path_template = "PREFIX+rdf%3A+++%3Chttp%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23%3E%0D%0APREFIX+rdfs%3A++%3Chttp%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23%3E%0D%0APREFIX+admingeo%3A+%3Chttp%3A%2F%2Fdata.ordnancesurvey.co.uk%2Fontology%2Fadmingeo%2F%3E%0D%0A%0D%0Aselect+%3Fa+%3Fname+%3Fcode%0D%0Awhere+%7B%3Fa+rdf%3Atype+admingeo%3A???+.%0D%0A+++++++%3Fa+rdfs%3Alabel+%3Fname+.%0D%0A+++++++%3Fa+admingeo%3AhasCensusCode+%3Fcode+.%7D"

  areas.each do |area_type, area_subtypes|
    area_subtypes.each do |area_subtype|
      url = base_url + path_template.sub("???", area_subtype)
      puts "===================\nAbout to get data from #{url}"
      results = Hpricot.XML(open(url)).search('result')
      puts "Retrieved #{results.size} results"
      results.each do |result|
        if ward = area_type.find_by_snac_id(result.search('literal').last.inner_text)
          os_id = result.at('uri').inner_text.scan(/\d+$/).to_s
          ward.update_attribute(:os_id, os_id)
          puts "updated #{area_type.to_s.downcase} (#{ward.name}) with os_id: #{os_id}"
        else
          puts "Could not find #{area_type.to_s.downcase} for result: #{result.inner_html}"
        end
      end
    end
  end
end

desc "Import County-District relationship from SPARQL endpoint"
task :import_country_districts_relationships => :environment do
  require 'hpricot'
  require 'open-uri'
  Council.find_all_by_authority_type("County").each do |county|
    begin
      doc = Hpricot.XML(open("http://statistics.data.gov.uk/doc/county/#{county.snac_id}.rdf"))
      districts = doc.search('administrative-geography:district').collect{ |d| d["rdf:resource"].scan(/local-authority-district\/(\w+)$/).to_s }
      puts "Found #{districts.size} districts for #{county.name}"
      districts.each do |snac_id|
        Council.find_by_snac_id(snac_id).update_attribute(:parent_authority_id, county.id)
      end
    rescue Exception => e
      puts "There was an error getting/processing info for #{county.name}: #{e.inspect}"
    end
  end
end

desc "add council twitter ids"
task :add_council_twitter_ids => :environment do
  auth_data = YAML.load_file("#{RAILS_ROOT}/config/twitter.yml")["production"]
  base_url = "http://api.twitter.com/1/Directgov/ukcouncils/members.xml?cursor="
  cursor = "-1"
  require 'hpricot'
  require 'httpclient'
  client = HTTPClient.new
  client.set_auth(nil, auth_data["login"], auth_data["password"])
  while cursor != '0' do
    doc = Hpricot.XML(client.get_content(base_url+cursor))
    cursor = doc.at('next_cursor').inner_text
    doc.search('users>user').each do |member|
      m_url = URI.parse(member.at('url').inner_text.strip).host

      m_id = member.at('screen_name').inner_text
      if council = Council.find(:first, :conditions => ["url LIKE ?", "%#{m_url}%"])
        puts "Found twitter url for #{council.name}: #{m_id}"
        council.update_attribute(:twitter_account, m_id)
      else
        puts "Failed to find council with url: #{m_url}"
      end
    end
  end
end

desc "export sameAs relationships"
task :export_sameas_relationships => :environment do
  FasterCSV.open(File.join(RAILS_ROOT, "db/csv_data/same_as_export.csv"), "w") do |csv|
    Council.all(:conditions => "snac_id IS NOT NULL").each do |council|
      csv << ["http://openlylocal/id/councils/#{council.id}", "http://statistics.data.gov.uk/id/local-authority/#{council.snac_id}", council.os_id&&"http://data.ordnancesurvey.co.uk/id/#{council.os_id}"]
    end
    Ward.find_in_batches(:conditions => "snac_id IS NOT NULL") do |batch|
      batch.each do |ward|
        csv << ["http://openlylocal/id/wards/#{ward.id}", "http://statistics.data.gov.uk/id/local-authority/#{ward.snac_id}", ward.os_id&&"http://data.ordnancesurvey.co.uk/id/#{ward.os_id}"]
      end
    end
  end
end

desc "geocode council offices"
task :geocode_councils => :environment do
  include Geokit::Geocoders
  Council.find_all_by_lat(nil).each do |council|
    loc=MultiGeocoder.geocode(council.address)
    if loc.success
      council.update_attributes(:lat => loc.lat, :lng => loc.lng)
      puts "Geocoded #{council.name} (#{council.address}):\nlat, lng: #{loc.lat}, #{loc.lng} (#{loc.full_address})"
    else
      puts "Problem Geocoding #{council.name}"
    end
  end
end
