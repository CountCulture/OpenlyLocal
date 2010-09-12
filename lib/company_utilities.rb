module CompanyUtilities
  
  class Client
    require 'companies_house'
    CompaniesHouse.sender_id = COMPANIES_HOUSE_SENDER_ID
    CompaniesHouse.password = COMPANIES_HOUSE_PASSWORD
    NO_COMPANY_DETAIL_TYPES =  %w(GN IC NA NO RC SI NI IP NF NP NR SP NL NZ SR)
    
    
    def get_vat_info(vat_number)
      return if vat_number.blank?
      doc = Hpricot(_http_get("http://ec.europa.eu/taxation_customs/vies/viesquer.do?ms=GB&iso=GB&vat=#{vat_number}"))
      info = doc.at('table.vat.answer ~ table')
      title = info.at('td[text()*=Name]').next_sibling.inner_text.squish.sub(/\s!!.+/,'') #remove trading as info
      address = info.at('td[text()*=Address]').next_sibling.at('font').inner_html.gsub(/(<br \/>)+/, ', ').squish
      RAILS_DEFAULT_LOGGER.debug "Found info for VAT number #{vat_number}: title = #{title}, address = #{address}"
      res = { :title => title, :address_in_full => address }
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.debug "Problem getting info for VAT number #{vat_number}: #{e.inspect}"
      return nil
    end
        
    def find_company_by_name(name)
      n_name = name.gsub('&', ' and ').squish
      return unless resp = search_companies_house_for(n_name)
      RAILS_DEFAULT_LOGGER.debug "Response from Companies House API for name_search for #{n_name}:\n#{resp.inspect}"
      poss_companies = resp.co_search_items
      unless match = Matcher.match_company(:poss_companies => poss_companies, :name => name)
        sleep 1
        poss_companies = search_companies_house_for(name, :data_set => 'FORMER').co_search_items
        match = Matcher.match_company(:poss_companies => poss_companies, :name => name)
      end
      return nil unless match
      sleep 1
      company_details_for(match.company_number)
    end
    
    def company_details_for(company_number)
      return if company_number.blank?
      company_details = CompaniesHouse.company_details(company_number) 
      RAILS_DEFAULT_LOGGER.debug "Response from Companies House API for details for company with company number #{company_number}:\n#{company_details.inspect}"
      hash_from_company_details(company_details)
    end

    protected
    def _http_get(url)
      return if RAILS_ENV=='test'
      RAILS_DEFAULT_LOGGER.debug "About to fetch info from CompaniesOpenHouse from: #{url}"
      open(url).read
    end
    
    def hash_from_company_details(company_details)
      return unless company_details
      res_hsh = {}
      res_hsh[:company_number] = company_details.company_number
      res_hsh[:title] = company_details.company_name
      res_hsh[:address_in_full] = company_details.reg_address.address_lines.join(', ') rescue nil
      res_hsh[:previous_names] = company_details.previous_names.collect{|pn| pn.company_name} rescue nil
      res_hsh[:sic_codes] = (company_details.sic_codes.respond_to?(:sic_texts) ? company_details.sic_codes.sic_texts : [company_details.sic_codes.sic_text]) rescue nil
      res_hsh[:status] = company_details.company_status
      res_hsh[:company_type] = company_details.company_category rescue nil
      res_hsh[:incorporation_date] = company_details.incorporation_date rescue nil
      res_hsh[:country] = company_details.country_of_origin
      res_hsh.delete_if{ |k,v| v.blank? }
    end
    
    def search_companies_house_for(name, options={})
      return if RAILS_ENV=='test'
      CompaniesHouse.name_search(name, options)
    end
  end
  
  module Matcher
    extend self
    
    def match_company(args)
      return unless args[:poss_companies]
      poss_companies = args[:poss_companies].group_by(&:company_name)
      # poss_companies.detect{|c| c.search_match=='EXACT'} || args[:poss_companies].detect{ |c| Company.normalise_title(c.company_name) == Company.normalise_title(args[:name]) }
      return if poss_companies.blank?
      companies = poss_companies.detect do |c_name, comps|
          Company.normalise_title(c_name) == Company.normalise_title(args[:name]) || comps.any?{ |c| c.search_match == "EXACT" }
      end.try(:last)
      return if companies.blank?

      # companies.sort_by{ |c| [c.company_index_status] }
      companies = companies.sort_by do |c|
        priority = 0
        priority -= 2 if c.company_index_status.nil?
        priority -= 1 unless c.company_number.match(/[A-Z]/)
        priority
      end
      companies.first
      
    end
  end
  
end