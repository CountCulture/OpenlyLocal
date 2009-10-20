class Service < ActiveRecord::Base
  validates_presence_of :category, 
                        :lgsl,
                        :lgil,
                        :service_name,
                        :authority_level,
                        :url
end                                