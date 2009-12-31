class OnsDatasetTopic < ActiveRecord::Base
  belongs_to :ons_dataset_family
  belongs_to :dataset_topic_grouping
  has_many :ons_datapoints
  validates_presence_of :title, :ons_dataset_family_id#, :ons_uid

  def extended_title
    muid_type ? "#{title} (#{muid_type})" : title
  end

  def muid_format
    muid_entry = NessUtilities::Muids[muid]
    return if muid_entry.blank?
    muid_entry[1]
  end

  def muid_type
    muid_entry = NessUtilities::Muids[muid]
    return if muid_entry.blank?
    muid_entry[0]
  end
  
  # returns all ancestors, furthest away first, to allow breadcrumbs to be built
  def parents
    [ons_dataset_family.statistical_dataset, ons_dataset_family]
  end

  # updates datapoints for all councils and emails results. NB Is used by Delayed::Job
  def perform
    results = process
    AdminMailer.deliver_admin_alert!(:title => "ONS Dataset Topic updated", :details => "Successfully process ONS Dataset Topic: #{title} (id: #{id})")
  end

  # Updates datapoints for all councils with ness_id. NB called proess so can be easily run by delayed job
  def process
    Council.all(:conditions => "ness_id IS NOT NULL").each do |council|
      update_datapoints(council)
    end
  end
  
  def short_title
    self[:short_title].blank? ? self[:title] : self[:short_title]
  end

  def update_datapoints(council)
    return if council.ness_id.blank?
    wards = council.wards
    raw_datapoints = NessUtilities::RawClient.new('ChildAreaTables', [['ParentAreaId', council.ness_id], ['LevelTypeId', '14'], ['Variables', ons_uid]]).process_and_extract_datapoints
    logger.debug { "Found #{raw_datapoints.size} raw datapoints for #{council.name} wards:\n #{raw_datapoints.inspect}" }
    raw_datapoints.collect do |rdp|
      next unless ward = wards.detect{|w| w.ness_id == rdp[:ness_area_id]}
      dp = ons_datapoints.find_or_initialize_by_area_type_and_area_id('Ward', ward.id)
      dp.update_attributes(:value => rdp[:value])
      dp
    end
  end

end
