class Charity < ActiveRecord::Base
  validates_presence_of :title, :charity_number
  validates_uniqueness_of :charity_number
end
