desc "Scrape Met Police for neighbourhoods" 
task :import_met_police_neighbourhoods => :environment do
  require 'hpricot'
  require 'open-uri'
  Council.find_all_by_authority_type("London Borough").each do |borough|
    if link = Hpricot(open("http://maps.met.police.uk/access.php?area=#{borough.snac_id}")).at('ul.related-links a[text()*=homepage]')
      borough.update_attribute(:police_neighbourhood_url, link[:href])
      puts "Successfully updated #{borough.name} with #{link[:href]}"
    end
    
    borough.wards.each do |ward|
      next if ward.snac_id.blank?
      begin
      doc = Hpricot(open("http://maps.met.police.uk/access.php?area=#{ward.snac_id}"))
      url = doc.at('ul.related-links a[@href*="www.met.police.uk/teams"]')[:href]
      ward.update_attribute(:police_neighbourhood_url, url)
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
