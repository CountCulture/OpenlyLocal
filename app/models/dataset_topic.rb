class DatasetTopic < ActiveRecord::Base
  belongs_to :dataset_family
  belongs_to :dataset_topic_grouping
  has_many :datapoints, :dependent => :destroy
  validates_presence_of :title, :dataset_family_id#, :ons_uid

  def extended_title
    muid_type ? "#{title} (#{muid_type})" : title
  end

  def muid_format
    muid_entry = Muids[muid]
    return if muid_entry.blank?
    muid_entry[1]
  end

  def muid_type
    muid_entry = Muids[muid]
    return if muid_entry.blank?
    muid_entry[0]
  end
  
  # returns all ancestors, furthest away first, to allow breadcrumbs to be built
  def parents
    [dataset_family.dataset, dataset_family]
  end

  # updates datapoints for all councils and emails results. NB Is used by Delayed::Job
  def perform
    results = process
    AdminMailer.deliver_admin_alert!(:title => "ONS Dataset Topic updated", :details => "Successfully process ONS Dataset Topic: #{title} (id: #{id})")
  end

  # Updates datapoints for all councils with ness_id. NB called proess so can be easily run by delayed job
  def process
    update_council_datapoints
    Council.all(:conditions => "ness_id IS NOT NULL").each do |council|
      update_ward_datapoints(council)
    end
  end
  
  def short_title
    self[:short_title].blank? ? self[:title] : self[:short_title]
  end
  
  def update_council_datapoints
    councils = Council.all(:conditions => "ness_id IS NOT NULL")
    if raw_datapoints = NessUtilities::RestClient.new(:get_tables, :areas => councils.collect(&:ness_id), :variables => ons_uid).response
      logger.debug { "Found #{raw_datapoints.size} raw datapoints for #{title} councils:\n #{raw_datapoints.inspect}" }
      create_datapoints_from(raw_datapoints, councils)
    else
      logger.debug { "No raw datapoints for #{title} council:\n #{raw_datapoints.inspect}" }
    end
  end

  def update_ward_datapoints(council)
    return if council.ness_id.blank?
    wards = council.wards
    if raw_datapoints = NessUtilities::RestClient.new(:get_child_area_tables, :parent_area_id => council.ness_id, :level_type_id => 14, :variables => ons_uid).response
      logger.debug { "Found #{raw_datapoints.size} raw datapoints for #{council.name} wards:\n #{raw_datapoints.inspect}" }
      create_datapoints_from(raw_datapoints, wards)
    else
      logger.debug { "No raw datapoints for #{council.name} wards:\n #{raw_datapoints.inspect}" }
    end
  end
  
  private
  def create_datapoints_from(raw_datapoints, areas)
    raw_datapoints.collect do |rdp|
      next unless area = areas.detect{|a| a.ness_id == rdp[:ness_area_id]}
      dp = datapoints.find_or_initialize_by_area_type_and_area_id(area.class.to_s, area.id)
      dp.update_attributes(:value => rdp[:value])
      dp
    end
  end

end
