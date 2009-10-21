class LdgService < ActiveRecord::Base
  BaseUrl = "http://local.direct.gov.uk/LDGRedirect/index.jsp?"
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
    response = _http_get(ldg_url)
    return nil unless response && (response.status == 302) && (poss_dest_url = response.header['location'].first)
    return nil unless dest_resp = _http_get(poss_dest_url)
    dest_resp.status == 200 ? poss_dest_url : nil
  end
  
  def url_for(council)
    BaseUrl + "LGSL=#{lgsl}&LGIL=#{lgil}&AgencyId=#{council.ldg_id}&Type=Single"
  end
  
  protected
  def _http_get(url)
    begin
      @client ||= HTTPClient.new
      @client.get(url)
    rescue Exception => e
      logger.debug "Problem getting data from #{url}: #{e.inspect}"
      return nil
    end
    
  end
end
