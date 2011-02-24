class ParishCouncil < ActiveRecord::Base
  include TitleNormaliser::Base
  
  validates_presence_of :title, :os_id
end
