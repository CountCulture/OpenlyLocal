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
  police_forces = PoliceForce.all(:conditions => 'npia_id IS NOT NULL')
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
    if police_force = PoliceForce.first(:conditions => "url LIKE '%#{URI.parse(force_url).host||force_url}%'")
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
    if council = Council.find(:first, :conditions => ["name LIKE ?", "%#{council_name.sub(/UA/,'').strip}%"])
      puts "Found match for #{council_name}: #{council.name}"
      if force = PoliceForce.find(:first, :conditions => ["name LIKE ?", "%#{force_name}%"])
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
    if poss_force = PoliceForce.find(:first, :conditions => ["name LIKE ?", "%#{eic.short_name.sub(/county/i,'').strip}%"])
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
  PoliceForce.first(:conditions => "name LIKE 'Dyfed%'").update_attribute(:name, "Dyfed-Powys Police")
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
      force = PoliceForce.first(:conditions => ["name LIKE ?", "%#{title.gsub(/Police|Authority/,'').strip}%"])
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


