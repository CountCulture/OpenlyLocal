module CharityUtilities
  
  class Client
    BaseUrl = 'http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/'
    CharityCommissionUrl = 'http://www.charitycommission.gov.uk'
    require 'nokogiri'
    
    attr_reader :charity_number
    
    def initialize(args={})
      @charity_number = args[:charity_number]
    end
    
    def get_details
      main_page = Nokogiri.HTML(_http_get(BaseUrl + "SearchResultHandler.aspx?RegisteredCharityNumber=#{charity_number}&SubsidiaryNumber=0"))

      financials_link = main_page.at('a#ctl00_ctl00_CharityDetailsLinks_lbtnFinancialHistory')
      financials_data = financials_link ? finance_data_from(BaseUrl+financials_link[:href]) : extract_finance_data(main_page)
      contacts_link = main_page.at('a#ctl00_ctl00_CharityDetailsLinks_lbtnContactTruestees')

      contacts_data = contact_data_from(BaseUrl+contacts_link[:href])
      framework_link = main_page.at('a#ctl00_ctl00_CharityDetailsLinks_lbtnGovernance')
      framework_data = frameworks_data_from(BaseUrl+framework_link[:href])
      detailed_info_from_front_page(main_page).merge(:accounts => financials_data).merge(framework_data).merge(contacts_data)
    end
    
        
    def charity_details_for(charity_number)
      return if charity_number.blank?
      attribs = {}
      client = HTTPClient.new
      # p "About to get info for charity_number: #{charity_number}"
      initial_url = "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/SearchResultHandler.aspx?RegisteredCharityNumber=#{charity_number}&SubsidiaryNumber=0"
      p "fetching info from #{initial_url}"
      # contact_page = Hpricot(open(initial_url))
      # contact_page = Nokogiri.HTML(open(initial_url)) # use Nokogiri Hpricot has probs with this website
      # attribs[:telephone] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_lblPhone').inner_text.scan(/[\d\s]+/).to_s.squish rescue nil
      # attribs[:email] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlEmail').inner_text.squish rescue nil
      # attribs[:website] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlWebsite')[:href] == 'http://' ? nil : contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlWebsite')[:href] rescue nil
      # attribs[:contact_name] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_lblContactName').try(:inner_text).try(:squish)
      # attribs[:address_in_full] = contact_page.search('.ContactAddress:not(#ctl00_MainContent_ucDisplay_ucContactDetails_lblContactName)').collect{|s|s.inner_text}.delete_if(&:blank?).join(', ') rescue nil
      begin
        # overview_redirect_url = ("http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/SearchResultHandler.aspx?SearchKeywords=#{charity_number}")
        # resp = client.get(overview_redirect_url)
        # overview_url = "http://www.charitycommission.gov.uk" + resp.header["Location"].first
        # overview_page = Hpricot(open(overview_url))
        # attribs[:activities] = overview_page.at('#ctl00_MainContent_ucDisplay_ucActivities_ucTextAreaInput_txtTextEntry').inner_text.squish rescue nil
        # attribs[:date_registered ] = overview_page.at('#ctl00_MainContent_ucDisplay_ucDateRegistered_ucTextInput_txtData').inner_text.squish rescue nil
        # attribs[:date_removed ] = overview_page.at('#ctl00_MainContent_ucDisplay_ucDateRemoved_ucTextInput_txtHolder').inner_text.squish rescue nil
        # accounts_date,income,spending = overview_page.at('#ctl00_MainContent_ucFinancialComplianceTable_gdvFinancialAndComplianceHistory tr[td]').search('td').collect{|td| td.inner_text} rescue nil
      rescue Exception => e
        puts "Problem get overview for charity #{charity.title} (#{charity_number}): #{e.inspect}\n#{e.backtrace}"
      end
      # framework_page = Hpricot(open(BaseUrl + "CharityFramework.aspx?RegisteredCharityNumber=#{charity_number}"))
      # attribs[:date_registered] ||= framework_page.at('#ctl00_MainContent_ucDisplay_ucDateRegistered_ucTextInput_txtData').inner_text.squish rescue nil
      # attribs[:date_removed] ||= framework_page.at('#ctl00_MainContent_ucDisplay_ucDateRemoved_ucTextInput_txtData').inner_text.squish rescue nil
      # attribs.merge!(:charity_commission_url => overview_url, :accounts_date => accounts_date, :income => income.to_s.gsub(/[^\d]/,''), :spending => spending.to_s.gsub(/[^\d]/,''))
      puts "Updating #{charity.title} with: #{attribs.inspect}"
      charity.update_attributes(attribs.delete_if{ |k,v| v.blank?})
      RAILS_DEFAULT_LOGGER.debug "Response from CharityCommission website for details for charity with charity number #{charity_number}:\n#{charity_details.inspect}"
      hash_from_charity_details(charity_details)
    end
    
    # def add_subsidiary_charities
    #   
    # end
    
    def finance_data_from(url)
      doc = Hpricot(_http_get(url))
      extract_finance_data(doc)
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.debug "Problem getting finance data from #{url}:\n#{e.inspect}"
      nil
    end
    
    def contact_data_from(url)
      contact_page = Nokogiri.HTML(_http_get(url)) # use Nokogiri as Hpricot has probs with this website
      res = {}
      res[:telephone] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_lblPhone').inner_text.scan(/[\d\s]+/).to_s.squish rescue nil
      res[:email] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlEmail').inner_text.squish rescue nil
      res[:website] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlWebsite')[:href] == 'http://' ? nil : contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_hlWebsite')[:href] rescue nil
      res[:contact_name] = contact_page.at('#ctl00_MainContent_ucDisplay_ucContactDetails_lblContactName').try(:inner_text).try(:squish)
      res[:address_in_full] = contact_page.search('.ContactAddress:not(#ctl00_MainContent_ucDisplay_ucContactDetails_lblContactName)').collect{|s|s.inner_text}.delete_if(&:blank?).join(', ') rescue nil
      trustees = contact_page.search('#ctl00_CentrePanelContent .ScrollingSelectionLeftColumn a').collect{ |t| { :full_name => t.inner_text, :uid =>  t[:href].scan(/TID=(\d+)/).to_s } }
      res.merge(:trustees => trustees)
    end
    
    def frameworks_data_from(url)
      frameworks_page = Nokogiri.HTML(_http_get(url)) # use Nokogiri as Hpricot has probs with this website
      res = {}
      res[:date_registered] = frameworks_page.at('#ctl00_MainContent_ucDisplay_ucDateRegistered_ucTextInput_txtData').inner_text.squish rescue nil
      res[:date_removed] = frameworks_page.at('#ctl00_MainContent_ucDisplay_ucDateRemoved_ucTextInput_txtData').inner_text.squish rescue nil
      res[:governing_document] = frameworks_page.at('#ctl00_MainContent_ucDisplay_ucGovDocDisplay_lblDisplayLabel').inner_text.squish rescue nil
      res[:other_names] = frameworks_page.at('#ctl00_MainContent_ucDisplay_ucOtherNames_lblDisplayLabel').inner_text.squish rescue nil
      res
    end

    protected
    def _http_get(url)
      return if RAILS_ENV=='test'
      RAILS_DEFAULT_LOGGER.debug "About to fetch info from CharityCommission website: #{url}"
      open(url).read
    end
    
    def detailed_info_from_front_page(page)
      res = {}
      res[:title] = page.at("#ctl00_charityStatus_spnCharityName").inner_text.squish
      res[:employees] = page.at('#TablesAssetsLiabilitiesAndPeople td[text()=Employees]~td').try(:inner_text)
      res[:volunteers] = page.at('#TablesAssetsLiabilitiesAndPeople td[text()=Volunteers]~td').try(:inner_text)
      res[:activities] = page.at('#ctl00_MainContent_ucDisplay_ucActivities_ucTextAreaInput_txtTextEntry').inner_text.squish rescue nil
      asset_res = {}
      if asset_info = page.at('#TablesAssetsLiabilitiesAndPeople')
        [:own_use_assets, :long_term_investments, :other_assets, :total_liabilities].each { |attrib| asset_res[attrib] = asset_info.at("td[text()*='#{attrib.to_s.humanize}']~td").inner_text rescue nil }
      end
      income_res = {}
      if income_info = page.at('#TablesIncome')
        [:voluntary, :trading, :investment, :charitable, :other, :investment_gains].each { |attrib| income_res[attrib] = income_info.at("td[text()*='#{attrib.to_s.humanize}']~td").inner_text rescue nil }
      end
      spending_res = {}
      if spending_info = page.at('#TablesSpending')
        [:generating_voluntary_income, :governance, :trading, :investment_management, :charitable_activities, :other].each { |attrib| spending_res[attrib] = spending_info.at("td[text()*='#{attrib.to_s.humanize}']~td").inner_text rescue nil }
      end
      res[:financial_breakdown] = { :income => income_res, :spending => spending_res, :assets => asset_res }.delete_if{ |k,v| v.blank? }
      res
    end
    
    def extract_finance_data(page)
      # p page unless page.search('#ctl00_MainContent_ucFinancialComplianceTable_gdvFinancialAndComplianceHistory tr')[1..-1]
      page.search('#ctl00_MainContent_ucFinancialComplianceTable_gdvFinancialAndComplianceHistory tr')[1..-1].collect do |row|
        res={}
        cols = row.search('td')
        res[:accounts_date] = cols[0].inner_text
        res[:income] = cols[1].inner_text.sub('*','')
        res[:spending] = cols[2].inner_text.sub('*','')
        res[:accounts_url] = CharityCommissionUrl + cols[5].at('a[@href*=ScannedAccounts]')[:href] rescue nil
        res[:sir_url] = CharityCommissionUrl + cols[5].at('a[@href*=SIR]')[:href] rescue nil
        res[:consolidated] = cols[1].inner_text =~ /\*/
        res
      end
    end

    
    # def create_charity(c)
    #   unless Charity.find_by_charity_number(c.first)
    #     c = Charity.create!(:charity_number => c.first, :title => c.last)
    #     puts "Added new charity: #{c.title} (#{c.charity_number})"
    #   end
    # end
  end
end