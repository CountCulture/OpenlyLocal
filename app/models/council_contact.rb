class CouncilContact < ActiveRecord::Base
  belongs_to :council
  validates_presence_of :council_id, :email, :name, :position
end
