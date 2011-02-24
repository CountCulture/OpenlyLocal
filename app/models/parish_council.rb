class ParishCouncil < ActiveRecord::Base
  validates_presence_of :title, :os_id
end
