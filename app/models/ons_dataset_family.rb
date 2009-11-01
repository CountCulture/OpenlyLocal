class OnsDatasetFamily < ActiveRecord::Base
  has_and_belongs_to_many :ons_subjects
  has_many :ons_datasets
  validates_presence_of :title
  validates_presence_of :ons_uid
end
