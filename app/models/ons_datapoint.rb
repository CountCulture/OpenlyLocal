class OnsDatapoint < ActiveRecord::Base
  validates_presence_of :value
  belongs_to :ons_dataset_topic
  belongs_to :ward
end
