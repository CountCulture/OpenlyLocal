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
    rescue Exception, Timeout::Error => e
      puts "****** Exception raised: #{e.inspect}"
      next
    end
    feed_urls = doc.search("link[@type*='rss']").collect{|l| l[:href].match(/^http:/) ? l[:href] : (council.url + l[:href])}
    council.update_attribute(:feed_url, feed_urls.first) # just save first one for the moment
    puts "#{council.title} feeds: #{feed_urls.inspect}"
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
