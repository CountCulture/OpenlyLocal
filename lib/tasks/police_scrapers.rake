desc "Populate Police Officers from NPIA api"
task :populate_police_officers => :environment do
  PoliceTeam.find_each(:include => :police_force) do |team|
    begin
      officers = team.update_officers
      puts "added updated #{officers.size} officers for #{team.name} (#{team.id})"
    rescue Exception => e
      puts "Problem updating officers for #{team.name} (#{team.id})"
    end
  end
end

desc "Populate Police Teams from NPIA api"
task :populate_police_team_info => :environment do
  police_teams = PoliceTeam.find_each(:include => :police_force, :conditions => {:description => nil}) do |team|
    team_details = NpiaUtilities::Client.new(:team, :force => team.police_force.npia_id, :team => team.uid).response
    team.update_attributes(:url => team_details["url_force"], :description => team_details["description"], :lat => team_details["latitude"], :lng => team_details["longitude"])
    puts "Updated #{team.extended_title}"
  end
end

desc "Populate Police Teams from NPIA api"
task :populate_police_teams => :environment do
  police_forces = PoliceForce.all(:conditions => "npia_id IS NOT NULL")
  police_forces.each do |force|
    teams = NpiaUtilities::Client.new(:teams, :force => force.npia_id).response
    teams["team"].collect{|t| {:name => t["name"], :uid => t["id"]}}.each do |team|
      force.police_teams.find_or_create_by_name_and_uid(team)
    end
  end
end

desc "Populate NPIA ids for police forces" 
task :populate_npia_ids => :environment do
  forces_info = NpiaUtilities::Client.new(:forces).response
  police_forces = PoliceForce.all
  forces_info["force"].each do |force_info|
    force_url = force_info["url_force"]
    engagement_method_urls = [force_info["engagement_methods"]["method"]].flatten.collect{ |m| m["url"] }
    social_sites = SocialNetworkingUtilities::IdExtractor.extract_from(engagement_method_urls)
    if police_force = PoliceForce.first(:conditions => "UPPER(url) LIKE '%#{(URI.parse(force_url).host || force_url).upcase}%'")
      police_force.attributes = social_sites.merge(:npia_id => force_info["id"], :crime_map => force_info["url_crimemapper"])
      police_force.save!
      puts "Updated force matching #{force_info["name"]}: #{police_force.name} (id = #{force_info['id']}, social media sites = #{social_sites.inspect})"
    else
      puts "*** Could not find force matching #{force_info["name"]} (#{force_url})"
    end
  end
end


desc "Scrape Met Police for neighbourhoods" 
task :import_met_police_neighbourhoods => :environment do
  require 'hpricot'
  require 'open-uri' 
  Council.find_all_by_authority_type("London Borough").each do |borough|
    if link = Hpricot(open("http://maps.met.police.uk/access.php?area=#{borough.snac_id}")).at('ul.related-links a[text()*=homepage]')
      borough.update_attribute(:police_force_url, link[:href])
      puts "Successfully updated #{borough.name} with #{link[:href]}"
    end
    
    borough.wards.each do |ward|
      next if ward.snac_id.blank?
      begin
      doc = Hpricot(open("http://maps.met.police.uk/access.php?area=#{ward.snac_id}"))
      url = doc.at('ul.related-links a[@href*="www.met.police.uk/teams"]')[:href]
      ward.update_attribute(:police_force_url, url)
      puts "Successfully updated #{ward.name} with #{url}"
      rescue Exception => e
        puts "There was an error getting/processing info for #{ward.name}: #{e.inspect}"
      end    
    end
  end
end

desc "Scrape police forces" 
task :scrape_police_forces => :environment do
  require 'hpricot'
  require 'open-uri'
  doc = Hpricot(open("http://www.police.uk/forces.htm")).search("ul#forcesmap li>a:first-of-type").each do |force|
    begin
      pf = PoliceForce.create!(:name => force.inner_text, :url => force[:href])
      puts "Successfully added #{pf.name}"
    rescue Exception => e
      puts "Problem adding #{force.inspect}: #{e.inspect}"
    end
  end
end


desc "Connect PoliceForce to LA" 
task :connect_police_force_to_la => :environment do
  rows = FasterCSV.read(File.join(RAILS_ROOT, "db/csv_data/police_LA_table.csv")).to_a
  rows.each do |row| # group by council SNAC id
    council_name, area, force_name = row
    if council = Council.find(:first, :conditions => ['UPPER(name) LIKE ?', "%#{council_name.sub(/UA/,'').strip.upcase}%"])
      puts "Found match for #{council_name}: #{council.name}"
      if force = PoliceForce.find(:first, :conditions => ['UPPER(name) LIKE ?', "%#{force_name.upcase}%"])
        council.update_attribute(:police_force_id, force.id)
        puts "Updated #{council.name} with force: #{force.name}"
      else
        puts "Failed to find match for #{force_name}"
      end
    else
      puts "Failed to find match for #{council_name}"
    end
  end
  psni = PoliceForce.find_or_create_by_url("http://www.psni.police.uk/", :name => "Police Service of Northern Ireland")
  Council.find_all_by_country_and_police_force_id("Northern Ireland", nil).each do |nic|
    nic.update_attribute(:police_force_id, psni.id)
  end
  puts "=============\nThe following councils do not have police forces:"
  all_forces = PoliceForce.all
  Council.find_all_by_police_force_id(nil, :order => "name ASC").each do |eic|
    puts eic.name
    if poss_force = PoliceForce.find(:first, :conditions => ['UPPER(name) LIKE ?', "%#{eic.short_name.sub(/county/i,'').strip.upcase}%"])
      puts "Possible force: #{poss_force.name}. Is this correct? (y/n)"
      response = $stdin.gets.chomp
      eic.update_attribute(:police_force_id, poss_force.id) && next if response == "y"
    end
    all_forces.each_with_index do |force, i|
      puts "#{i+1}) #{force.name}"
    end
    puts "Please choose force by number (n to skip): "
    response = $stdin.gets.chomp
    next if response == "n"
    eic.update_attribute(:police_force_id, all_forces[response.to_i-1].id)
  end
end

desc "Get wikipedia info for Police Forces" 
task :get_police_force_wikipedia_info => :environment do
  PoliceForce.first(:conditions => "UPPER(name) LIKE 'DYFED%'").update_attribute(:name, "Dyfed-Powys Police")
  require 'hpricot'
  require 'httpclient'
  client = HTTPClient.new
  PoliceForce.all.each do |force|
    poss_url = "http://en.wikipedia.org/wiki/#{URI.escape(force.name.split(" - ").first.strip.sub('&', 'and').gsub(/\s/,'_'))}"
    resp = client.get(poss_url)
    if resp.status == 200
      puts "Found wikipedia page for #{force.name}: #{poss_url}"
      force.update_attribute(:wikipedia_url, poss_url)
    else
      puts "Prob finding wikipedia page for #{force.name}. Status: #{resp.status}\n#{resp.header.inspect}"
    end
  end
end

desc "Get WDTK ids for Police Forces"
task :get_police_force_wdtk_ids  => :environment do
  require 'hpricot'
  require 'open-uri'
  doc = Hpricot(open("http://www.whatdotheyknow.com/body/list/police"))
  force_links = doc.search('.body_listing a')
  PoliceForce.all.each do |force|
    short_name = force.name.gsub(/Police|Constabulary|Service/,'').sub("&", "and").sub(/ \- .+$/,'').sub('-',' ').strip
    if f=force_links.detect{ |fl| fl.inner_text.sub("&", "and") =~ /#{short_name}/ }
      wdtk_name = f[:href].scan(/body\/(.+)/).to_s
      puts "Found entry for #{short_name}: #{f.inner_text} (WDTK name = #{wdtk_name})"
      force.update_attribute(:wdtk_name, wdtk_name)
    else
      puts "Couldn't match force (#{short_name})"
    end
  end
end

desc "Get info for Police Athorities" 
task :get_police_authority_info => :environment do
  require 'hpricot'
  doc = Hpricot(open("http://www.apa.police.uk/APA/About+Police+Authorities/Police+Authority+Addresses/"))
  authorities = doc.search('.innertables td[a]')
  authorities.each do |auth|
    begin
      url = auth.at('a')[:href]
      el, title = [], []
      #messy but only way given HTML is such as mess
      auth.traverse_all_element{|e| el<<e if e.kind_of?(Hpricot::Text) || e.respond_to?(:children)&&e.children.blank?}
      el = el.compact.collect{ |e| e.inner_text.gsub(/ /, '').squish }.delete_if{ |e| e.blank? }
      title << el.shift
      title << el.shift if el.first=~/authority/i
      title = title.join(" ").squish.titleize
      telephone = el.pop.scan(/[\d\s]+$/).to_s.strip
      postcode = el.last.slice!(/\w*\d*\s\w*\d*$/)
      address = el.join(', ').titleize
      force = PoliceForce.first(:conditions => ['UPPER(name) LIKE ?', "%#{title.gsub(/Police|Authority/,'').strip.upcase}%"])
      puts title, url, address.titleize, postcode, telephone, force, "===="
      PoliceAuthority.create!(:title => title, :telephone => telephone, :police_force => force, :url => url, :address => [address, postcode].join(" "))
    rescue Exception => e
      puts "Problem parsing #{auth.inner_text}t\n#{e.inspect}"
    end
  end
end

desc "Get WDTK ids for Police Authorities"
task :get_police_authority_wdtk_ids  => :environment do
  require 'hpricot'
  require 'open-uri'
  doc = Hpricot(open("http://www.whatdotheyknow.com/body/list/police_authority"))
  auth_links = doc.search('.body_listing a')
  PoliceAuthority.all.each do |auth|
    short_name = auth.name.gsub(/Police|Authority/,'').sub("&", "and").sub(/ \- .+$/,'').sub('-',' ').strip.downcase
    if a=auth_links.detect{ |al| al.inner_text.sub("&", "and").downcase =~ /#{short_name}/ }
      wdtk_name = a[:href].scan(/body\/(.+)/).to_s
      puts "Found entry for #{short_name}: #{a.inner_text} (WDTK name = #{wdtk_name})"
      auth.update_attribute(:wdtk_name, wdtk_name)
    else
      puts "Couldn't match force (#{short_name})"
    end
  end
end

desc "Connect Wards and Police Teams"
task :connect_wards_and_police_teams  => :environment do
  defunkt_teams = PoliceTeam.defunkt.all
  wards_without_current_police_teams = Ward.all(:include => [:boundary, :council], :conditions => "police_team_id IS NULL AND snac_id IS NOT NULL")
                                        + defunkt_teams.collect{ |t| t.wards }.flatten.compact
  police_forces = PoliceForce.all
  wards_without_current_police_teams.each do |ward|
    next if ward.council.authority_type == 'County' || !ward.boundary
    centrepoint = ward.boundary.centrepoint
    client = NpiaUtilities::Client.new(:geocode_team, :q => [centrepoint.lat, centrepoint.lng].join(','))
    begin
      resp = client.response
      force = police_forces.detect{ |f| f.npia_id == resp["team"]["force_id"] }
      police_team = force.police_teams.find_by_uid(resp["team"]["team_id"])
      ward.update_attribute(:police_team_id, police_team.id)
      puts "Associated ward (#{ward.name}) with police_team (#{police_team.name})"
    rescue Exception => e
      puts "Problem associating team with ward: #{ward.name} (#{ward.id}): #{e.inspect}\n #{e.backtrace}\n\n#{resp}"
    end
  end
end

desc "Populate Crime Types from NPIA api"
task :populate_crime_types => :environment do
  NpiaUtilities::Client.new(:crime_types).response['crime_type'].each do |ct|
    crime_type = CrimeType.create!(:uid => ct['id'], :name => ct['name_single'], :plural_name => ct['name_plural'])    
    puts "Create crime type: #{crime_type.name}"
  end
end

desc "Populate Crime Areas from NPIA api"
task :populate_crime_areas => :environment do
  PoliceForce.all.each do |force|
    next unless force.crime_areas.empty?
    raw_areas = NpiaUtilities::Client.new(:crime_areas, :force => force.npia_id).response
    puts "===========\nAbout to create crime areas for #{force.name}"
    PoliceRakeUtils.create_crime_areas(raw_areas, :police_force => force)
  end
end

desc "Populate Crime Areas info from NPIA api"
task :populate_crime_area_info => :environment do
  CrimeArea.find_each(:conditions => {:crime_level_cf_national => nil}) do |crime_area|
    area_info = NpiaUtilities::Client.new(:crime_area, :force => crime_area.police_force.npia_id, :area => crime_area.uid).response
    crime_area.update_attributes(:crime_mapper_url => area_info['url_crimemapper'], :feed_url => area_info['url_rss'], :crime_level_cf_national => area_info['crime_level'], :crime_rates => area_info['crime_rates']['total'], :total_crimes => area_info['total_crimes']['total'])
    puts "Updated crime area #{crime_area.name}"
  end
end

desc "Connect postcode and crime areas"
task :connect_postcodes_and_crime_areas => :environment do
  Postcode.find_each(:conditions => {:crime_area_id => nil, :country => '064'}) do |postcode|
    response = NpiaUtilities::Client.new(:geocode_crime_area, :q => postcode.code).response rescue nil
    begin
      next unless response && response['areas']['area']
      crime_areas = response['areas']['area']
      police_force = PoliceForce.find_by_npia_id(crime_areas.first['force_id'])
      if crime_area = police_force.crime_areas.find_by_uid(crime_areas.detect{ |ca| ca['level'] == '4' }['area_id'])
        postcode.update_attribute(:crime_area_id, crime_area.id)
        puts "updated postcode #{postcode.code}"
      else
        puts "Failed to match postcode #{postcode.code} to crime area"
      end
    rescue Exception => e
      postcode.update_attribute(:crime_area_id, -1)
      puts "problem updating postcode (#{postcode.code}) with crime_area: #{e.inspect}\nResponse = #{response}"
    end
  end
end

module PoliceRakeUtils
  def self.create_crime_areas(resp_hash, options={})
    return unless resp_hash&&resp_hash['area']
    [resp_hash['area']].flatten.each do |area_hash|
      new_area = options[:police_force].crime_areas.create!(:uid => area_hash['id'], :level => area_hash['level'].to_i, :name => area_hash['name'], :parent_area_id => options[:parent_area_id] )
      puts "created new area #{new_area.name} for #{options[:police_force].name}"
      if child_areas = area_hash['child_areas']&&area_hash['child_areas']['area']
        create_crime_areas(area_hash['child_areas'], :parent_area_id => new_area.id, :police_force => options[:police_force])
      end
    end
  end
end
