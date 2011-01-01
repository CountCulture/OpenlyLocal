class LdgService < ActiveRecord::Base
  BaseUrl = "http://local.direct.gov.uk/LDGRedirect/index.jsp?"
  SPEND_OVER_500_LGSL = 1465
  
  has_many :services, :include => :council, :order => 'councils.name'
  validates_presence_of :category, 
                        :lgsl,
                        :lgil,
                        :service_name,
                        :authority_level,
                        :url
                        
  def title
    service_name
  end
  
  def destination_url(council)
    ldg_url = url_for(council)
    response = follow_redirects_to(ldg_url)
    return nil unless response&&(dest_resp, poss_dest_url = response)
    title = Nokogiri::HTML.parse(dest_resp.content).at("title").try(:inner_text)
    { :url => poss_dest_url, :title => title}
  rescue Exception => e
    Rails.logger.debug { "Exception getting ldg url #{ldg_url} for council #{council.title}: #{e.inspect}" }
    nil
  end
  
  def url_for(council)
    BaseUrl + "LGSL=#{lgsl}&LGIL=#{lgil}&AgencyId=#{council.ldg_id}&Type=Single"
  end
  
  protected
  
  def follow_redirects_to(url)
    begin
      retry_number = 0
      while retry_number < 5
        res = _http_get(url)
        status = res.status
        if HTTP::Status.successful?(status)
          return [res, url]
        elsif HTTP::Status.redirect?(status)
          url = redirect_url(url, res)
          retry_number += 1
        else
          raise "unexpected response: #{res.header.inspect}"
        end
      end
    rescue Exception => e
      logger.debug "Problem getting data from #{url}: #{e.inspect}"
      return nil
    end
  end
  
  def redirect_url(from, resp)
    newuri = URI.parse(resp.header['location'].first)
    newuri = (from.is_a?(URI::HTTP) ? from : URI.parse(from)) + newuri unless newuri.is_a?(URI::HTTP)
    newuri.to_s # that's all we need, and makes testing easier
  end
  
  def _http_get(url)
    return nil if RAILS_ENV=="test"
    begin
      client = HTTPClient.new
      client.get(url)
    rescue Exception => e
      logger.debug "Problem getting data from #{url}: #{e.inspect}"
      return nil
    end    
  end
end
