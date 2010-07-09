class Investigation < ActiveRecord::Base
  validates_presence_of :organisation_name, :standards_body
end
