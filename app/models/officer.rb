class Officer < ActiveRecord::Base
  validates_presence_of :last_name, :position, :council_id
  belongs_to :council
end
