class Election < ActiveRecord::Base
  belongs_to :ward
  validates_presence_of :date, :ward_id
end
