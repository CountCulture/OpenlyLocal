class StatisticalDataset < ActiveRecord::Base
  has_many :ons_dataset_families, :dependent => :destroy
  validates_presence_of :title, :originator
  validates_uniqueness_of :title
end
