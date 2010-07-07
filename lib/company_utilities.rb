module CompanyUtilities
  
  class Client

    def get_basic_info(company_number)
      return if company_number.blank?
      resp_hash = JSON.parse(_http_get("http://companiesopen.org/uk/#{company_number}.js"))['company'] rescue nil
      return unless resp_hash
      { :title => resp_hash['name'],
        :wikipedia_url => resp_hash['wikipedia_url'],
        :company_type => resp_hash['company_category'],
        :incorporation_date => resp_hash['incorporation_date'],
        :address_in_full => resp_hash['address'],
        :status => resp_hash['company_status']
      }.delete_if{|k,v| v.blank?}
    end
    
    def find_company_from_name(name)
      resp_array = JSON.parse(_http_get("http://companiesopen.org/search?q=#{CGI.escape name}&f=js")) rescue nil
      return if resp_array.blank?
      resp_array.collect do |company_info|
        { :title => company_info['company']['name'],
          :company_number => company_info['company']['company_number'],
          :wikipedia_url => company_info['company']['wikipedia_url'],
          :company_type => company_info['company']['company_category'],
          :incorporation_date => company_info['company']['incorporation_date'],
          :address_in_full => company_info['company']['address'],
          :status => company_info['company']['company_status']
        }.delete_if{|k,v| v.blank?}
      end
    end

    protected
    def _http_get(url)
      return if RAILS_ENV=='test'
      RAILS_DEFAULT_LOGGER.debug "About to fetch info from CompaniesOpenHouse from: #{url}"
      open(url).read
    end
  end
end