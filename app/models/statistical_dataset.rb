class StatisticalDataset < ActiveRecord::Base
  has_many :ons_dataset_families, :dependent => :destroy
  has_many :ons_dataset_topics, :through => :ons_dataset_families
  validates_presence_of :title, :originator
  validates_uniqueness_of :title

  # Returns Array of Datapoints (strictly BareDatapoints, which are sort of composite 
  # datapoints created when there isn't a real datapoint we can use), each representing 
  # the aggrated value of all datapoints for the datasetfamily, grouped by councils.
  # See also OnsDatasetFamily#calculated_datapoints_for_councils
  def calculated_datapoints_for_councils
    return if ons_dataset_families.any?{ |t| t.calculation_method.blank? }
    raw_results = OnsDatapoint.sum( :value, 
                                    :group => :area_id, 
                                    :conditions => { :area_type => 'Council', :ons_dataset_topic_id => ons_dataset_topics.collect(&:id)}, 
                                    :order => "sum_value DESC").to_a
    return if raw_results.blank?
    raw_results = raw_results.select{ |r| r.last > 0.0 }.transpose
    councils = Council.find(raw_results.first) # .. so we have to go through hoops if we want to return councils as keys to values, rather than council_ids. B fetching councils gives us default order which we have to blow out
    # There's also the the problem that default_scope on councils returns in named order, not order we asked for them in, and something funny going on with OrderedHash returned from
    # sum, which means order is screwing up
    res = []
    muid_format, muid_type = ons_dataset_topics.first.muid_format, ons_dataset_topics.first.muid_type
    raw_results.first.each_with_index do |council_id, i|
      council = councils.detect{ |c| c.id == council_id }
      res<< BareDatapoint.new(:area => council, :value => raw_results.last[i], :muid_format => muid_format, :muid_type => muid_type)
    end
    res
  end

end
