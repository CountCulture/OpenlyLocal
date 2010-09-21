desc "Populate UK Charities"
task :populate_charities => :environment do
  local_auth_list_page = Hpricot(open('http://www.charitycommission.gov.uk/ShowCharity/registerofcharities/mapping/Search.aspx'))
  local_auth_list = local_auth_list_page.search('#ctl00_MainContent_ddlLA option')[1..-1].collect{|la| [la.inner_text, la[:value]]}
  puts "Found #{local_auth_list.size} authorities"
  local_auth_list.each do |la|
    begin
      puts "\n==================\nAbout to start getting charities in #{la.first}"
      url = "http://www.charitycommission.gov.uk/ShowCharity/registerofcharities/mapping/Map.aspx?ResultType=1&LocalAuthorityId=#{la.last}&Parameter=#{la.first.gsub(/\s/,'%20')}"
      results_page = Hpricot(open(url))
      charities = results_page.search('#charities_oDataList td.name span').collect{|e| [e.inner_text.scan(/^\d+/).to_s, e.inner_text.scan(/\d - (.+)/).to_s.squish] }
      puts "Found #{charities.size} charities:"
      charities.each { |c| create_charity(c) }
      client = HTTPClient.new
      next unless (no_of_pages = results_page.at('input#charities_hiddenPagesCount')[:value].to_i) > 1
      puts "About to fetch results from #{no_of_pages} more pages"
      no_of_pages.times do |i|
        viewstate = results_page.at('input#__VIEWSTATE')[:value]
        eventvalidation = results_page.at('input#__EVENTVALIDATION')[:value]
        results_page = Hpricot(client.post(url, "charities$hiddenPagesCount" => no_of_pages, "charities$hiddenCurrentPage" => i+1, "charities$btnGoToNext" => 'Next >', "__EVENTVALIDATION" => eventvalidation, "__VIEWSTATE" => viewstate).content)
        new_charities = results_page.search('#charities_oDataList td.name span').collect{|e| [e.inner_text.scan(/^\d+/).to_s, e.inner_text.scan(/\d - (.+)/).to_s.squish] }
        "Found #{new_charities.size} more charities:"
        new_charities.each do |c|
          create_charity(c)
        end
      end
    rescue Exception => e
      puts "**** Problem getting/parsing data: #{e.inspect}"
    end
  end
end


desc "Get Missing Charities"
task :get_missing_charities => :environment do
  %w(reg_now rem91).each do |file_name|
    File.open(File.join(RAILS_ROOT, "db/data/charities/#{file_name}.txt")).each do |file|
      file.each_line do |line|
        unless Charity.find_by_charity_number(charity_number = line.squish)
          puts "Getting details for missing charity (#{charity_number})"
          begin
            c = Charity.new(:charity_number => charity_number)
            if c.update_info
              puts "Added details for #{c.title}"
            else
              puts "Problem adding details for charity: #{c.errors.to_json}"
            end
          rescue Exception => e
            puts "**** Problem getting info for charity: #{e.inspect}"
          end
        end
      end
    end
    
  end
  base_url = "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/"
end

desc "Catch up newly created charities"
task :catch_up_with_new_charities => :environment do
  days_ago = 2
  charities, new_charity_count = [],1 # give new_charity_count non-zero value so loop runs at least once
  while charities.size != new_charity_count 
    start_date = (days_ago+4).days.ago.to_date
    end_date = days_ago.days.ago.to_date
    puts "About to get charities from #{start_date} to #{end_date}"
    charities = Charity.add_new_charities(:start_date => start_date, :end_date => end_date)
    new_charity_count = charities.select{|c| !c.new_record?}.size
    puts "Found #{charities.size} charities, #{charities.select{|c| !c.new_record?}.size} of them new"
    days_ago += 3
  end 
  
end



def create_charity(c)
  unless Charity.find_by_charity_number(c.first)
    c = Charity.create!(:charity_number => c.first, :title => c.last)
    puts "Added new charity: #{c.title} (#{c.charity_number})"
  end
end
