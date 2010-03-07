class Poll < ActiveRecord::Base
  belongs_to :area, :polymorphic => true
  has_many :candidates
  validates_presence_of :date_held, :area_id, :area_type
  
end
