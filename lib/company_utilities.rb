module CompanyUtilities
  
  class Client
    
    def company_from_name(name)
      # require 'companies_house'
      return unless poss_companies = (find_possible_companies_from_name(name) || (name.match(/&/) ? find_possible_companies_from_name(name.gsub(/\s?&\s?/, ' and ')) : nil))
      if poss_companies.size == 1
        poss_companies.first
      else
        poss_companies.detect{ |pc| Company.normalise_title(pc[:title]) == Company.normalise_title(name) }
      end
    end

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
    
    def get_vat_info(vat_number)
      return if vat_number.blank?
      doc = Hpricot(_http_get("http://ec.europa.eu/taxation_customs/vies/viesquer.do?ms=GB&iso=GB&vat=#{vat_number}"))
      info = doc.at('table.vat.answer ~ table')
      title = info.at('td[text()*=Name]').next_sibling.inner_text.squish
      address = info.at('td[text()*=Address]').next_sibling.at('font').inner_html.gsub(/(<br \/>)+/, ', ').squish
      { :title => title,
        :address_in_full => address }
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.debug "Problem getting info for VAT number #{vat_number}: #{e.inspect}"
      return nil
    end
    
    def find_possible_companies_from_name(name)
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