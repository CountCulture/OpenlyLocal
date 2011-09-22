module CharityUtilities
  
  class Client
    BaseUrl = 'http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/'
    CharityCommissionUrl = 'http://www.charitycommission.gov.uk'
    require 'nokogiri'
    
    attr_reader :charity_number
    
    def initialize(args={})
      @charity_number = args[:charity_number]
    end
    
    def company_number_for(charity)
      url = "http://opencorporates.com/reconcile/gb?query=#{URI.escape(charity.title)}"
      RAILS_DEFAULT_LOGGER.debug "reconciling company number from url: #{url}"
      resp = _http_get(url)
      RAILS_DEFAULT_LOGGER.debug "reconciliation response: #{resp}"
      first_result = JSON.parse(resp)['result'].first rescue nil
      return unless first_result
      first_result['score'] >= 0.6 ? first_result['id'].scan(/\d+$/).to_s : nil
    end
    
    def get_details
      main_page = Nokogiri.HTML(_http_get(BaseUrl + "SearchResultHandler.aspx?RegisteredCharityNumber=#{charity_number}&SubsidiaryNumber=0"))

      financials_link = main_page.at('a#ctl00_ctl00_CharityDetailsLinks_lbtnFinancialHistory')
      financials_data = financials_link ? finance_data_from(BaseUrl+financials_link[:href]) : extract_finance_data(main_page)
      contacts_link = main_page.at('a#ctl00_ctl00_CharityDetailsLinks_lbtnContactTruestees')

      contacts_data = contacts_link ? contact_data_from(BaseUrl+contacts_link[:href]) : {}
      framework_link = main_page.at('a#ctl00_ctl00_CharityDetailsLinks_lbtnGovernance')
      framework_data = framework_link ? frameworks_data_from(BaseUrl+framework_link[:href]) : frameworks_data_from(main_page)
      detailed_info_from_front_page(main_page).merge(:accounts => financials_data).merge(framework_data).merge(contacts_data)
    end
        
    def finance_data_from(url)
      doc = Hpricot(_http_get(url))
      extract_finance_data(doc)
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.debug "Problem getting finance data from #{url}:\n#{e.inspect}"
      nil
    end
    
    def get_recent_charities(start_date=nil, end_date=nil)
      start_date ||= 4.days.ago
      end_date ||= start_date + 4.days
      # new_charities = []
      url = CharityCommissionUrl + "/SHOWCHARITY/RegisterOfCharities/AdvancedSearch.aspx"

      client = HTTPClient.new
      search_page =  Nokogiri.HTML(client.get_content(url)) #pick up cookie, viewstates etc
      viewstate = search_page.at('#__VIEWSTATE')[:value]
      eventvalidation = search_page.at('#__EVENTVALIDATION')[:value]
      
      post_url = CharityCommissionUrl + '/ShowCharity/RegisterOfCharities/AdvancedSearch.aspx'
      
      post_params = {
        "ctl00$CorporateHeader1$Header$Text2" => "",
        "ctl00$CorporateHeader1$Header$BasicSearch$radio" => "rdName",
        "ctl00$CorporateHeader1$Header$BasicSearch$textBoxSearch" => "",
        "ctl00$MainContent$searchforControl$SearchForRadioButtons" => "radioButtonOnlyRegistered",
        "ctl00$MainContent$keywordSearchControlInstance$keywordsSubControl$textBoxKeywords" => "",
        "ctl00$MainContent$keywordSearchControlInstance$keywordsSubControl$keywordControl" => "radioButtonAll",
        "ctl00$MainContent$keywordSearchControlInstance$searchinSubControl$checkBoxCharityName" => "on",
        "ctl00$MainContent$picklistControl$areaDropDownControl$dropDownListArea" => "In any area",
        "ctl00$MainContent$searchdatesRegistration$searchdatesSearchdateFrom$DropDownListDay" => start_date.day.to_s,
        "ctl00$MainContent$searchdatesRegistration$searchdatesSearchdateFrom$DropDownListMonth" => Date::MONTHNAMES[start_date.month],
        "ctl00$MainContent$searchdatesRegistration$searchdatesSearchdateFrom$DropDownListYear" => "1",
        "ctl00$MainContent$searchdatesRegistration$searchdatesSearchdateTo$DropDownListDay" => end_date.day.to_s,
        "ctl00$MainContent$searchdatesRegistration$searchdatesSearchdateTo$DropDownListMonth" => Date::MONTHNAMES[end_date.month],
        "ctl00$MainContent$searchdatesRegistration$searchdatesSearchdateTo$DropDownListYear" => "1",
        "ctl00$MainContent$searchdatesRemoved$searchdatesSearchdateFrom$DropDownListDay" => "",
        "ctl00$MainContent$searchdatesRemoved$searchdatesSearchdateFrom$DropDownListMonth" => "",
        "ctl00$MainContent$searchdatesRemoved$searchdatesSearchdateFrom$DropDownListYear" => "0",
        "ctl00$MainContent$searchdatesRemoved$searchdatesSearchdateTo$DropDownListDay" => "",
        "ctl00$MainContent$searchdatesRemoved$searchdatesSearchdateTo$DropDownListMonth" => "",
        "ctl00$MainContent$searchdatesRemoved$searchdatesSearchdateTo$DropDownListYear" => "0",
        "ctl00$MainContent$incomeRangeControl$dropDownListIncomeRange" => "0",
        "ctl00$MainContent$buttonSearch" => "Search",
        "client" => "my_frontend",
        "output" => "xml_no_dtd",
        "proxystylesheet" => "my_frontend",
        "site" => "default_collection",
        "__EVENTTARGET" => "",
        "__EVENTARGUMENT" => "",
        "__EVENTVALIDATION" => eventvalidation, 
        "__VIEWSTATE" => viewstate
      }
      
      # Get first page
      RAILS_DEFAULT_LOGGER.debug("About to get info from #{post_url} with params:\n#{post_params.inspect}")
      if resp = client.post(post_url, post_params)
        resp = client.get_content(CharityCommissionUrl+resp.header['Location'].first)
        results_page = Nokogiri.HTML(resp)
        new_charities = extract_charities_from_search_page(results_page)
        additional_pages = (results_page.search('input.PageNumbers')[-2][:value].to_i - 1) rescue nil
        return new_charities unless additional_pages
        post_url = CharityCommissionUrl + "/SHOWCHARITY/RegisterOfCharities/SearchMatchList.aspx?RegisteredCharityNumber=0&SubsidiaryNumber=0"
        additional_pages.times do |i|
          viewstate = results_page.at('input#__VIEWSTATE')[:value]
          eventvalidation = results_page.at('input#__EVENTVALIDATION')[:value]
          results_page = Nokogiri.HTML(client.post_content(post_url, 
                                                                      "__EVENTVALIDATION" => eventvalidation, 
                                                                      "__VIEWSTATE" => viewstate,
                                                                      "ctl00$CorporateHeader1$Header$BasicSearch$radio" => "rdName",
                                                                      "ctl00$CorporateHeader1$Header$BasicSearch$textBoxSearch" => "Enter name or number",
                                                                      "ctl00$CorporateHeader1$Header$Text2" => "",
                                                                      "ctl00$MainContent$gridView$ctl28$ctl#{'%02d' % (i>0 ? i+2 : i+1)}" => i+2,
                                                                      "client" => "my_frontend",
                                                                      "output" => "xml_no_dtd",
                                                                      "proxystylesheet" => "my_frontend",
                                                                      "site" => "default_collection"
                                                                      ))
          additional_charities = extract_charities_from_search_page(results_page)
          new_charities += additional_charities
        end
      end
      new_charities
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
    
    def frameworks_data_from(url_or_doc)
      p url_or_doc
      frameworks_page = url_or_doc.is_a?(String) ? Nokogiri.HTML(_http_get(url_or_doc)) : url_or_doc # use Nokogiri as Hpricot has probs with this website
      res = {}
      res[:date_registered] = frameworks_page.at('#ctl00_MainContent_ucDisplay_ucDateRegistered_ucTextInput_txtData').inner_text.squish rescue nil
      res[:date_removed] = frameworks_page.at('#ctl00_MainContent_ucDisplay_ucDateRemoved_ucTextInput_txtData').inner_text.squish rescue nil
      res[:governing_document] = frameworks_page.at('#ctl00_MainContent_ucDisplay_ucGovDocDisplay_lblDisplayLabel').inner_text.squish rescue nil
      other_names = frameworks_page.at('#ctl00_MainContent_ucDisplay_ucOtherNames_lblDisplayLabel').inner_text.squish rescue nil
      res[:other_names] = other_names == 'None' ? nil : other_names
      p res
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
      res[:employees] = clean_number(page.at('#TablesAssetsLiabilitiesAndPeople td[text()=Employees]~td').try(:inner_text))
      res[:volunteers] = clean_number(page.at('#TablesAssetsLiabilitiesAndPeople td[text()=Volunteers]~td').try(:inner_text))
      res[:activities] = page.at('#ctl00_MainContent_ucDisplay_ucActivities_ucTextAreaInput_txtTextEntry').inner_text.squish rescue nil
      asset_res = {}
      if asset_info = page.at('#TablesAssetsLiabilitiesAndPeople')
        [:own_use_assets, :long_term_investments, :other_assets, :total_liabilities].each { |attrib| asset_res[attrib] = clean_number(asset_info.at("td[text()*='#{attrib.to_s.humanize}']~td").inner_text) rescue nil }
      end
      income_res = {}
      if income_info = page.at('#TablesIncome')
        [:voluntary, :trading, :investment, :charitable, :other, :investment_gains].each { |attrib| income_res[attrib] = clean_number(income_info.at("td[text()*='#{attrib.to_s.humanize}']~td").inner_text) rescue nil }
      end
      spending_res = {}
      if spending_info = page.at('#TablesSpending')
        [:generating_voluntary_income, :governance, :trading, :investment_management, :charitable_activities, :other].each { |attrib| spending_res[attrib] = clean_number(spending_info.at("td[text()*='#{attrib.to_s.humanize}']~td").inner_text) rescue nil }
      end
      res[:financial_breakdown] = { :income => income_res, :spending => spending_res, :assets => asset_res }.delete_if{ |k,v| v.blank? }
      res
    end
    
    def extract_finance_data(page)
      return if (rows = page.search('#ctl00_MainContent_ucFinancialComplianceTable_gdvFinancialAndComplianceHistory tr')).blank?
      rows[1..-1].collect do |row|
        res={}
        cols = row.search('td')
        res[:accounts_date] = cols[0].inner_text
        res[:income] = clean_number(cols[1].inner_text.sub('*',''))
        res[:spending] = clean_number(cols[2].inner_text.sub('*',''))
        res[:accounts_url] = CharityCommissionUrl + cols[5].at('a[@href*=ScannedAccounts]')[:href] rescue nil
        res[:sir_url] = CharityCommissionUrl + cols[5].at('a[@href*=SIR]')[:href] rescue nil
        res[:consolidated] = cols[1].inner_text =~ /\*/
        res
      end
    end

    def clean_number(raw_number)
      return if raw_number.blank?
      raw_number.gsub(/[^\d\.\-]/,'')
    end

    def extract_charities_from_search_page(page)
      # page.search('#ctl00_MainContent_gridView tr').collect{ |row| {:charity_number => row.at('a').inner_text, :title => row.search('a')[1].inner_text.squish } }
      # page.search('#ctl00_MainContent_gridView tr[td[@valign="top"]]').collect{ |row| {:charity_number => row.at('a').inner_text, :title => row.search('a')[1].inner_text.squish } }
      page.search('//table/tr[count(td)>2]').collect{ |row| {:charity_number => row.at('a').inner_text, :title => row.search('a')[1].inner_text.squish } }

    end

  end
end