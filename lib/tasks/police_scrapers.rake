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

