class OnsDatasetTopic < ActiveRecord::Base
  belongs_to :ons_dataset_family
  validates_presence_of :title, :ons_uid, :ons_dataset_family_id

  def muid_format
    muid_entry = NessUtilities::Muids[muid]
    return if muid_entry.blank?
    muid_entry[1]
  end
end
