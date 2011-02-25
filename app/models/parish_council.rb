class ParishCouncil < ActiveRecord::Base
  belongs_to :council
  include TitleNormaliser::Base
  include SpendingStatUtilities::Base
  include SpendingStatUtilities::Payee
  
  validates_presence_of :title, :os_id
end
