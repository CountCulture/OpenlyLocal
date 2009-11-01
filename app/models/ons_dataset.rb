class OnsDataset < ActiveRecord::Base
  belongs_to :ons_dataset_family
  validates_presence_of :start_date
  validates_presence_of :end_date
  validates_presence_of :ons_dataset_family_id
  validates_uniqueness_of :start_date, :scope => :ons_dataset_family_id
  
  def title
    "#{start_date} - #{end_date}"
  end
  
  def extended_title
    "#{ons_dataset_family.title} #{start_date} - #{end_date}"
  end
end
