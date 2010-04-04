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
  Council.all.each do |council|
    loc=MultiGeocoder.geocode(council.address)
    if loc.success && loc.accuracy < 5
      puts "Could not accurately geocode #{council.name} (#{council.address}):\nlat, lng: #{loc.lat}, #{loc.lng} (#{loc.full_address})\n Accuracy: #{loc.accuracy}"
    elsif loc.success
      council.update_attributes(:lat => loc.lat, :lng => loc.lng)
      puts "Geocoded #{council.name} (#{council.address}):\nlat, lng: #{loc.lat}, #{loc.lng} (#{loc.full_address})"
    else
      puts "Problem Geocoding #{council.name}"
    end
  end
end

desc "Import CIPFA codes for councils"
task :import_council_cipfa_codes => :environment do
  require 'pp'
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/council_cipfa_codes.csv"), :headers => false).to_a
  headings = rows.shift
  councils=Council.all.each do |council|
    if row = rows.detect{ |r| r.first.gsub(/&| and/, '').squish.match(/#{council.short_name}/i) }
      puts "========\nFound match for #{council.name} (#{council.short_name}): #{row.first}"
      council.update_attribute(:cipfa_code, row.last)
      puts "Updated #{council.name} with cipfa_code: #{row.last}"
      rows.delete(row)
    else
      puts "***Couldn't find match for #{council.name} (#{council.short_name})"
    end
  end
  puts "========\nThe following rows were unmatched:"
  pp rows

end

desc "Import council regions"
task :import_council_regions => :environment do
  require 'hpricot'
  require 'open-uri'
  
  Regions.each do |region_name,values|
    begin
      doc = Hpricot.XML(open("http://statistics.data.gov.uk/doc/government-office-region/#{values.first}.rdf"))
      region = doc.at('skos:prefLabel').inner_text
      snac_ids = doc.search('administrative-geography:district|administrative-geography:county').collect{ |d| d["rdf:resource"].scan(/\/(\w+)$/).to_s }
      puts "Found #{snac_ids.size} councils for region #{region} (#{values.first})"
      snac_ids.each do |snac_id|
        if council = Council.find_by_snac_id(snac_id)
          council.update_attribute(:region, region)
        end
      end
    rescue Exception => e
      puts "There was an error getting/processing info for #{region}: #{e.inspect}"
    end
  end
end

desc "Match 1010 councils"
task :match_1010_councils => :environment do  
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/1010_councils_18-1-10.csv"))
  FasterCSV.open(File.join(RAILS_ROOT, "db/csv_data/matched_1010_councils_18-1-10.csv"), "w") do |csv|
    councils=Council.all.each do |council|
      if row = rows.detect{ |r| r.first.gsub(/&| and/, '').squish.match(/#{council.short_name}\b/i) }
        puts "========\nFound match for #{council.name} (#{council.short_name}): #{row.first}"
        csv << [council.name, council.snac_id]
        puts "Matched #{council.name} with 1010 info"
        rows.delete(row)
      else
        puts "***Couldn't find match for #{council.name} (#{council.short_name})"
      end
    end
  end
  p "Following entries were unmatched:", rows
end

desc "Import 1010 councils"
task :import_1010_councils => :environment do  
  snac_ids = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/matched_1010_councils_18-1-10.csv")).collect do |row|
    row[1] #snac_ids
  end
  puts "Updating #{snac_ids.size} records"
  Council.update_all("signed_up_for_1010='0'") #flush existing records
  Council.update_all("signed_up_for_1010='1'", :snac_id => snac_ids)
end

desc "Populate pension funds"
task :populate_pension_funds => :environment do
  require 'hpricot'
  regions = Hpricot(open("http://www.lgps.org.uk/lge/core/page.do?pageId=99259")).search("#middle-col p a")
  fund_links = regions.collect do |region_link|
    puts "Getting funds from http://www.lgps.org.uk/lge/#{region_link[:href]}"
    Hpricot(open("http://www.lgps.org.uk/lge/" + region_link[:href])).search(".bodyContent td:first-of-type a").collect{ |f| f[:href] }
  end
  fund_links.flatten.each do |link|
    doc = Hpricot(open("http://www.lgps.org.uk/lge/" + link))
    name = doc.at("title").inner_text
    fund = PensionFund.find_or_create_by_name(name.match(/Pension/i) ? name : "#{name} Pension Fund")
    attribs = {}
    details = doc.at('.bodyContent')
    attribs[:telephone] = details.at("th[text()*=Telephone]").nodes_at(2).first.try(:inner_text)
    raw_url = details.at("a[@href*=http]").try(:inner_text)
    attribs[:url] = raw_url.to_s.match(/http:/) ? raw_url : raw_url&&"http://#{raw_url}"
    attribs[:email] = details.at("a[@href*=mailto]").try(:inner_text)
    attribs[:fax] = details.at("th[text()*=Fax]").nodes_at(2).first.try(:inner_text)
    attribs[:address] = details.at("th[text()*=Address]").nodes_at(2).first.try(:inner_html).to_s.gsub(/<.?p>/,'').gsub("<br />", ", ").strip
    fund.update_attributes(attribs)
    p fund
  end 
end

desc "Associate councils and pension funds"
task :associate_pension_funds => :environment do 
  require 'pp'
  ni_fund = PensionFund.find_or_initialize_by_name("NILGOSC")
  ni_fund.update_attributes(:address => "411 Holywood Road, Belfast, BT4 2LP, Northern Ireland", :telephone => "0845 308 7345", :fax => "0845 308 7344", :email => "info@NILGOSC.org.uk", :url => "http://www.nilgosc.org.uk/")
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/las_to_pension_funds.csv"))
  councils = Council.all
  pension_funds = PensionFund.all
  matched_funds = []
  unmatched_councils = councils.dup
  councils.each do |council|
    if row = rows.detect{ |r| r.first.gsub(/&| and/, '').squish.match(/#{council.short_name}\b/i) }
      puts "========\nFound match for #{council.name} (#{council.short_name}): #{row.first}"
      fund_short_name = row.last.gsub(/Pension|Fund|Council|Authority|Scheme/i, '').squish
      
      if fund = PensionFund.first(:conditions => "name LIKE '%#{fund_short_name}%'")
        council.update_attribute(:pension_fund, fund)
        unmatched_councils.delete(council)
        puts "Updated #{council.name} with pension fund: #{fund.name}"
        rows.delete(row)
        matched_funds << fund
      else
        puts "****Failed to find record for #{row.last} (#{fund_short_name})"
      end
    else
      puts "***Couldn't find match for #{council.name} (#{council.short_name})"
    end
  end
  unmatched_councils_2 = unmatched_councils.dup
  unmatched_councils_2.each do |council|
    if parent_council = council.parent_authority
      council.update_attribute(:pension_fund, parent_council.pension_fund)
      unmatched_councils.delete(council)
      puts "Updated #{council.name} with pension fund: #{parent_council.pension_fund.name}"
    elsif council.country == 'Northern Ireland'
      council.update_attribute(:pension_fund, ni_fund)
      unmatched_councils.delete(council)
      puts "Updated #{council.name} with pension fund: #{ni_fund.name}"
    else
      puts "No parent authority for #{council.name}"
    end
  end
  unmatched_funds = pension_funds - matched_funds
  pp "Unmatched rows:", rows
  pp "#{unmatched_councils.size} Unmatched councils:", unmatched_councils.collect(&:name)
  pp "#{unmatched_funds.size} Unmatched funds:", unmatched_funds.collect(&:name)
end

desc "Import ONS GSS codes into councils, wards tables"
task :import_ons_gss_codes => :environment do
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/ons_data/gss_to_snac_ex_wales.csv")).to_a[1..-1] #skip header row
  
  areas = Council.all(:conditions => "snac_id IS NOT NULL") +  Ward.all(:conditions => "snac_id IS NOT NULL")
  areas.each do |area|
    if row = rows.detect{ |r| r[3] == area.snac_id }
      area.update_attribute(:gss_code, row[0])
      puts "Updated entry for #{area.title} (name in table: #{row[1]}). GSS code = #{row[0]}"
    else
      puts "**** Can't find entry for #{area.title} (snac_id: #{area.snac_id})"
    end
  end

end

desc "Import missing council lat longs"
task :import_missing_council_latlongs => :environment do
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/missing_council_latlongs.csv")).to_a
  councils_without_lat_longs = Council.all(:conditions => {:lat => nil, :lng => nil}).each do |council|
    if matched_row = rows.detect{|row| Council.normalise_title(row.first) == Council.normalise_title(council.name)}
      lat, lng = matched_row.last.split(",")
      council.update_attributes(:lat => lat.to_f, :lng => lng.to_f)
      puts "Updated #{council.name} with lat_long for #{matched_row.first} (#{matched_row.last})"
    else
      puts "*** Failed to match #{council.title}"
    end
  end
end

desc "Scrape annual audit letters"
task :scrape_annual_audit_letters => :environment do
  require 'hpricot'
  base_url = 'http://www.audit-commission.gov.uk'
  bodies = Council.all + PoliceAuthority.all
  (1..5).each do |page_no|
    download_pages = Hpricot(open(base_url + "/localgov/audit/annualauditletters/aal0809/Pages/list.aspx?ctype=ACAnnualAuditLetter&p=#{page_no}")).search("#midcolbox .document li a").collect{ |l| l[:href] }
    download_pages.each do |dp|
      pdf_link = Hpricot(open(base_url + dp)).at('#midcolbox .docdownload a')
      raw_body = pdf_link.inner_text.gsub(/annual audit.+$/im,'')
      if body = bodies.detect{|b| (b.name == raw_body) || (Council.normalise_title(raw_body) == Council.normalise_title(b.name)) }
        body.update_attribute(:annual_audit_letter, base_url + pdf_link[:href])
        puts "Updated #{body.name} with link to audit letter (#{raw_body}, #{base_url + pdf_link[:href]})"
      else
        puts "*** Could not found council matching #{raw_body}"
      end
    end
  end
end

desc "Import OS Ids for County Electoral Divisions"
task :import_os_county_division_ids => :environment do
  require 'hpricot'
  require 'open-uri'
  
  url = "http://api.talis.com/stores/ordnance-survey/services/sparql?query=PREFIX%20owl%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F2002%2F07%2Fowl%23%3E%0D%0APREFIX%20rdfs%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F2000%2F01%2Frdf-schema%23%3E%0D%0APREFIX%20xsd%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F2001%2FXMLSchema%23%3E%0D%0APREFIX%20foaf%3A%20%3Chttp%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2F%3E%0D%0APREFIX%20rdf%3A%20%3Chttp%3A%2F%2Fwww.w3.org%2F1999%2F02%2F22-rdf-syntax-ns%23%3E%0D%0APREFIX%20admingeo%3A%20%3Chttp%3A%2F%2Fdata.ordnancesurvey.co.uk%2Fontology%2Fadmingeo%2F%3E%0D%0APREFIX%20spatialrelations%3A%20%3Chttp%3A%2F%2Fdata.ordnancesurvey.co.uk%2Fontology%2Fspatialrelations%2F%3E%0D%0A%0D%0Aselect%20%3Fced%20%3Fcounty%20%3Fcedname%20%3Fcountyname%0D%0Awhere%0D%0A%7B%0D%0A%3Fcounty%20rdf%3Atype%20admingeo%3ACounty%20.%0D%0A%3Fced%20rdf%3Atype%20admingeo%3ACountyElectoralDivision%20.%0D%0A%3Fcounty%20spatialrelations%3Acontains%20%3Fced%20.%0D%0A%3Fced%20rdfs%3Alabel%20%3Fcedname%20.%0D%0A%3Fcounty%20rdfs%3Alabel%20%3Fcountyname%20.%0D%0A%7D"
  
  results = Hpricot.XML(open(url)).search('result')
  puts "Retrieved #{results.size} results"
  
  results = results.group_by{|r| r.at('binding[@name=county] uri').inner_text.scan(/\d+$/).to_s} #group by county os_id
  # counter = 0
  results.each do |county_os_id, wards|
    # counter +=1
    # break if counter > 5
    unless county = Council.find_by_os_id(county_os_id)
      puts "****County with os_id #{county_os_id} (#{county_name}) doesn't seem to exist"
      next
    end
    if county.wards.count > 0
      wards.each do |ward|
        if (ward_name = ward.at('binding[@name=cedname] literal').try(:inner_text)) && (matched_ward = county.wards.detect{|w| TitleNormaliser.normalise_title(w.name) == TitleNormaliser.normalise_title(ward_name)})
          ward_os_id = ward.at('binding[@name=ced] uri').inner_text.scan(/\d+$/).to_s
          matched_ward.update_attribute(:os_id, ward_os_id)
          puts "Matched #{ward_name} & #{matched_ward.name} for #{county.name} with os_id #{ward_os_id}"
        else
          puts "****Couldn't match #{ward_name} for #{county.name}"
        end
      end
    else
      puts "No wards for this county. Creating new ones"
      wards.each do |ward|
        new_ward = county.wards.create!(:os_id => ward.at('binding[@name=ced] uri').inner_text.scan(/\d+$/).to_s, :name => ward.at('binding[@name=cedname] literal').inner_text)
        puts "Created new ward (#{new_ward.name}) for #{county.name}"
      end
    end
  end
end

