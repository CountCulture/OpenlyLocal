desc "Import councillor twitter ids"
task :import_councillor_twitter_ids => :environment do
  grouped_rows = FasterCSV.read(File.join(RAILS_ROOT, "../../shared/csv_data/unmatched_councillor_tweeps.csv"), :headers => true).group_by{ |r| r["Council"] } # group by council
  councils = Council.all
  unmatched_rows = []
  grouped_rows.each do |council_name, rows|
    if council = councils.detect{ |c| Council.normalise_title(council_name) == Council.normalise_title(c.name) }
      puts "=====\nMatched #{council_name} (#{Council.normalise_title(council_name)}) against #{council.title}"
      if council.members.blank?
        puts "No members for this council"
        unmatched_rows += rows
        next
      end
      rows.each do |row|
        if member = council.members.detect { |m| m.last_name == row["CllrSurname"] && m.first_name =~ /#{row["CllrFirstName"]}/ }
          puts "Matched #{row['CllrFirstName']} #{row['CllrSurname']} to #{member.full_name}"
          blog_url = row["CllrWebsite"].blank? ? nil : row["CllrWebsite"]
          member.update_attributes(:twitter_account_name => row["CllrTwitter"], :blog_url => blog_url)
        else
          puts "**Can't find match for #{row['CllrFirstName']} #{row['CllrSurname']}"
          unmatched_rows << row
        end
      end
    else
      puts "=====\n*****Can't find match for #{council_name} (#{Council.normalise_title(council_name)})"
    end
  end
  
  puts "\n\nWriting #{unmatched_rows.size} unmatched records to file"
  FasterCSV.open(File.join(RAILS_ROOT, "../../shared/csv_data/unmatched_councillor_tweeps.csv"), "w") do |csv|
    csv << unmatched_rows.first.headers # write headers
    unmatched_rows.each do |row|
      csv << row
    end
  end
  
end

desc "Scrape Standards Board For England Cases"
task :scrape_sbe_cases => :environment do
  require 'open-uri'
  require 'hpricot'
  base_url = 'http://www.standardsforengland.gov.uk'
  links_to_auth_listings = Hpricot(open(base_url + '/CaseinformationReporting/SfEcasesummaries/')).search('.col1 a[@href*=/CaseinformationReporting/SfEcasesummaries/Casesummaries]')
  authority_pages = links_to_auth_listings.collect { |auth_list_link|
    Hpricot(open(base_url+auth_list_link[:href])).search('.col1 .arrow li a') 
  }.flatten
  puts "Found #{authority_pages.size} local authorities. Now scraping those authorities for cases..."
  investigation_links = authority_pages.collect { |ap| puts "fetching investigations for #{ap.inner_text}"; Hpricot(open(base_url + ap[:href])).search('.col1 a[text()*="Read in full"]') }.flatten
  puts "Found #{investigation_links.size} investigations. Now scraping for details of those investigations"
  investigation_links.each do |inv_link|
    begin
      inv_params = {}
      inv_params[:url] = base_url+inv_link[:href]
      inv_params[:standards_body] = "SBE"
      inv_params[:raw_html] = (case_details = Hpricot(open(base_url+inv_link[:href])).at('.col1')).inner_html
      inv_params[:uid] = case_details.at('a')[:name]
      inv_params[:organisation_name] = case_details.at('h1').inner_text.sub('Case Summary - ','')
      inv_params[:title] = NameParser.strip_all_spaces(case_details.at('td[text()*="Case no"] ~ td').inner_text)
      inv_params[:subjects] = NameParser.strip_all_spaces(case_details.at('td[text()*=Member] ~ td').inner_text)
      inv_params[:date_received] = NameParser.strip_all_spaces(case_details.at('td[text()*=received] ~ td').inner_text)
      inv_params[:date_completed] = case_details.at('script[text()*=completed]').inner_text.scan(/var type = \"([^"]+)/).to_s
      inv_params[:allegation] = NameParser.strip_all_spaces(case_details.search('h2[text()*=Allegation] ~ p:first-of-type').inner_text)
      inv_params[:result] = NameParser.strip_all_spaces(case_details.at('h2[text()*="Standards Board outcome"] ~ p').inner_text) ||
                              case_details.search('script[text()*=outcome]').collect{|s| s.inner_text.scan(/var type = \"([^"]+)/)}.flatten.to_s
      inv_params[:case_details] = DocumentUtilities.sanitize(case_details.to_html).sub(/.+Case Summary<\/strong><\/h2>/m,'').squish # details are everything after heading
      Investigation.create!(inv_params)
      puts "Added new investigation from #{inv_params[:url]}"
    rescue Exception => e
      puts "Problem getting investigation details from #{base_url+inv_link[:href]}: #{e.inspect}\n#{e.backtrace}"
    end
  end
end

desc "Scrape Local Government Ombudsman Cases"
task :scrape_lgo_cases => :environment do
  require 'open-uri'
  require 'hpricot'
  base_url = 'http://www.lgo.org.uk'
  links_to_categories = Hpricot(open(base_url + '/complaint-outcomes/')).search('li.subNav a|li.subNavTop a')
  category_archives = links_to_categories.collect { |cat_link|
    Hpricot(open(base_url+cat_link[:href])).search(".rightColumn .navText li a[@href*='#{cat_link[:href]}']")
  }.flatten
  puts "Found #{category_archives.size} category archives. Now scraping those archives for cases..."
  
  category_archives.each do |archive_link|
    "===========\nAdding cases for #{archive_link.inner_text}"
    case_links = Hpricot(open(base_url+archive_link[:href])).search('.promoText a').each do |case_link|
      url = base_url+case_link[:href]
       p Investigation.find_or_create_by_url( :url => url, 
                                           :title => case_link.inner_text, 
                                           :standards_body => 'LGO', 
                                           :organisation_name => NameParser.strip_all_spaces(case_link.inner_text.sub(/\(.+\)/,'')), 
                                           :allegation => NameParser.strip_all_spaces(case_link.parent.parent.children.last.inner_text))
    end
  end
end