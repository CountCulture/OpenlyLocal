class Charity < ActiveRecord::Base
  has_many :supplying_relationships, :class_name => "Supplier", :as => :payee
  include SpendingStatUtilities::Base
  
  validates_presence_of :title, :charity_number
  validates_uniqueness_of :charity_number
end
