class Service < ActiveRecord::Base
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
  
  def url_for(council)
    BaseUrl + "LGSL=#{lgsl}&LGIL=#{lgil}&AgencyId=#{council.ldg_id}&Type=Single"
  end
end                                