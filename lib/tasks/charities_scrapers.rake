desc "Populate England & Wales Charities"
task :populate_england_and_wales_charities => :environment do
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
  base_url = "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/"
  Charity.find_each(:conditions => {:date_registered => nil}) do |charity|
    client = HTTPClient.new
    p "About to get info for #{charity.title} (#{charity.charity_number})"
    initial_url = base_url + "ContactAndTrustees.aspx?RegisteredCharityNumber=#{charity.charity_number}" + ENV['URL_SUFFIX'].to_s
    p "fetching info from #{initial_url}"
    contact_page = Hpricot(open(base_url + "ContactAndTrustees.aspx?RegisteredCharityNumber=#{charity.charity_number}"))
    telephone = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_lblPhone').inner_text.scan(/[\d\s]+/).to_s.squish
    email = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlEmail').inner_text.squish
    website = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlWebsite')[:href] == 'http://' ? nil : contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlWebsite')[:href]
    begin
      overview_redirect_url = base_url + contact_page.at('a#ctl00_ctl00_CharityDetailsLinks_lbtnCharityOverview')[:href]
      resp = client.get(overview_redirect_url)
      overview_url = "http://www.charitycommission.gov.uk" + resp.header["Location"].first
      activities = Hpricot(open(overview_url)).at('#ctl00_MainContent_ucDisplay_ucActivities_ucTextAreaInput_txtTextEntry').inner_text.squish
    rescue Exception => e
      puts "Problem get overview for charity #{charity.title} (#{charity.charity_number}): #{e.inspect}\n#{e.backtrace}"
    end
    date_registered = Hpricot(open(base_url + "CharityFramework.aspx?RegisteredCharityNumber=#{charity.charity_number}")).at('#ctl00_MainContent_ucDisplay_ucDateRegistered_ucTextInput_txtData').inner_text.squish
    attribs = {:activities => activities, :telephone => telephone, :email => email, :website => website, :date_registered => date_registered, :charity_commission_url => overview_url}.delete_if{ |k,v| v.blank?}
    puts "Updating #{charity.title} with: #{attribs.inspect}"
    charity.update_attributes(attribs)
  end
end

def create_charity(c)
  unless Charity.find_by_charity_number(c.first)
    c = Charity.create!(:charity_number => c.first, :title => c.last)
    puts "Added new charity: #{c.title} (#{c.charity_number})"
  end
end
