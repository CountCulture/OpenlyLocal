class OnsDatasetTopic < ActiveRecord::Base
  belongs_to :ons_dataset_family
  has_many :ons_datapoints
  validates_presence_of :title, :ons_uid, :ons_dataset_family_id

  def extended_title
    "#{ons_dataset_family.title} #{title}"
  end

  def muid_format
    muid_entry = NessUtilities::Muids[muid]
    return if muid_entry.blank?
    muid_entry[1]
  end

  def update_datapoints(council)
    return if council.ness_id.blank?
    wards = council.wards
    raw_datapoints = NessUtilities::RawClient.new('ChildAreaTables', [['ParentAreaId', council.ness_id], ['LevelTypeId', '14'], ['Variables', ons_uid]]).process_and_extract_datapoints
    raw_datapoints.collect do |rdp|
      ward = wards.detect{|w| w.ness_id == rdp[:ness_area_id]}
      dp = ons_datapoints.find_or_initialize_by_ward_id(ward.id )
      dp.update_attribute(:value, rdp[:value])
      dp
    end
  end
end
