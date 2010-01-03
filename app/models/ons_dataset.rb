class OnsDataset < ActiveRecord::Base
  belongs_to :dataset_family
  validates_presence_of :start_date
  validates_presence_of :end_date
  validates_presence_of :dataset_family_id
  validates_uniqueness_of :start_date, :scope => :dataset_family_id
  
  def title
    "#{start_date} - #{end_date}"
  end
  
  def extended_title
    "#{dataset_family.title} #{start_date} - #{end_date}"
  end
end
