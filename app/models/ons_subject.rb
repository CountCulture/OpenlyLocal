class OnsSubject < ActiveRecord::Base
  has_and_belongs_to_many :ons_dataset_families
  validates_presence_of :title
  validates_presence_of :ons_uid
  validates_uniqueness_of :ons_uid

end
