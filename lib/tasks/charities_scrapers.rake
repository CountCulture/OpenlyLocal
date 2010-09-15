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

desc "Get Charity Details"
task :get_charity_details => :environment do
  require 'nokogiri'
  base_url = "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/"
  Charity.find_each(:conditions => {:date_registered => nil}) do |charity|
    attribs = {}
    client = HTTPClient.new
    p "About to get info for #{charity.title} (#{charity.charity_number})"
    initial_url = base_url + "ContactAndTrustees.aspx?RegisteredCharityNumber=#{charity.charity_number}" + ENV['URL_SUFFIX'].to_s
    p "fetching info from #{initial_url}"
    # contact_page = Hpricot(open(initial_url))
    contact_page = Nokogiri.HTML(open(initial_url)) # use Nokogiri Hpricot has probs with this website
    attribs[:telephone] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_lblPhone').inner_text.scan(/[\d\s]+/).to_s.squish rescue nil
    attribs[:email] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlEmail').inner_text.squish rescue nil
    attribs[:website] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlWebsite')[:href] == 'http://' ? nil : contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlWebsite')[:href] rescue nil
    attribs[:contact_name] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_lblContactName').try(:inner_text).try(:squish)
    attribs[:address_in_full] = contact_page.search('.ContactAddress:not(#ctl00_MainContent_ucDisplay_ucContactDetails_lblContactName)').collect{|s|s.inner_text}.delete_if(&:blank?).join(', ') rescue nil
    begin
      overview_redirect_url = ("http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/SearchResultHandler.aspx?SearchKeywords=#{charity.charity_number}")
      resp = client.get(overview_redirect_url)
      overview_url = "http://www.charitycommission.gov.uk" + resp.header["Location"].first
      overview_page = Hpricot(open(overview_url))
      attribs[:activities] = overview_page.at('#ctl00_MainContent_ucDisplay_ucActivities_ucTextAreaInput_txtTextEntry').inner_text.squish rescue nil
      attribs[:date_registered ] = overview_page.at('#ctl00_MainContent_ucDisplay_ucDateRegistered_ucTextInput_txtData').inner_text.squish rescue nil
      attribs[:date_removed ] = overview_page.at('#ctl00_MainContent_ucDisplay_ucDateRemoved_ucTextInput_txtHolder').inner_text.squish rescue nil
      accounts_date,income,spending = overview_page.at('#ctl00_MainContent_ucFinancialComplianceTable_gdvFinancialAndComplianceHistory tr[td]').search('td').collect{|td| td.inner_text} rescue nil
    rescue Exception => e
      puts "Problem get overview for charity #{charity.title} (#{charity.charity_number}): #{e.inspect}\n#{e.backtrace}"
    end
    framework_page = Hpricot(open(base_url + "CharityFramework.aspx?RegisteredCharityNumber=#{charity.charity_number}"))
    attribs[:date_registered] ||= framework_page.at('#ctl00_MainContent_ucDisplay_ucDateRegistered_ucTextInput_txtData').inner_text.squish rescue nil
    attribs[:date_removed] ||= framework_page.at('#ctl00_MainContent_ucDisplay_ucDateRemoved_ucTextInput_txtData').inner_text.squish rescue nil
    attribs.merge!(:charity_commission_url => overview_url, :accounts_date => accounts_date, :income => income.to_s.gsub(/[^\d]/,''), :spending => spending.to_s.gsub(/[^\d]/,''))
    puts "Updating #{charity.title} with: #{attribs.inspect}"
    charity.update_attributes(attribs.delete_if{ |k,v| v.blank?})
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

def create_charity(c)
  unless Charity.find_by_charity_number(c.first)
    c = Charity.create!(:charity_number => c.first, :title => c.last)
    puts "Added new charity: #{c.title} (#{c.charity_number})"
  end
end
