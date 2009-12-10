class OnsDatasetTopic < ActiveRecord::Base
  belongs_to :ons_dataset_family
  validates_presence_of :title, :ons_uid, :ons_dataset_family_id
end
