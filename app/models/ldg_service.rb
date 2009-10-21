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
    client = HTTPClient.new
    ldg_url = url_for(council)
    response = client.get(ldg_url)
    return nil unless response && (response.status == 302) && (poss_dest_url = response.header['location'].first)
    client.get(poss_dest_url).status == 200 ? poss_dest_url : nil
  end
  
  def url_for(council)
    BaseUrl + "LGSL=#{lgsl}&LGIL=#{lgil}&AgencyId=#{council.ldg_id}&Type=Single"
  end
end
