class ParishCouncil < ActiveRecord::Base
  include TitleNormaliser::Base
  belongs_to :council
  
  validates_presence_of :title, :os_id
end
