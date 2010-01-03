class DatasetFamily < ActiveRecord::Base
  has_and_belongs_to_many :ons_subjects
  has_many :ons_datasets
  has_many :dataset_topics, :dependent => :destroy
  has_many :datapoints, :through => :dataset_topics
  belongs_to :dataset
  validates_presence_of :title
  validates_presence_of :source_type
  validates_presence_of :dataset_id

  # Returns Array of Datapoints (strictly BareDatapoints, which are sort of composite 
  # datapoints created when there isn't a real datapoint we can use), each representing 
  # the aggrated value of all datapoints for the datasetfamily, grouped by councils.
  # See also Dataset#calculated_datapoints_for_councils
  def calculated_datapoints_for_councils
    return if calculation_method.blank?
    raw_results = datapoints.sum(:value, :group => :area_id, :conditions => {:area_type => 'Council'}, :order => "sum_value DESC").to_a #for some reason we can't group by polymorphic belongs_to
    return if raw_results.blank?
    raw_results = raw_results.select{ |r| r.last > 0.0 }.transpose
    councils = Council.find(raw_results.first) # .. so we have to go through hoops if we want to return councils as keys to values, rather than council_ids. B fetching councils gives us default order which we have to blow out
    # There's also the the problem that default_scope on councils returns in named order, not order we asked for them in, and something funny going on with OrderedHash returned from
    # sum, which means order is screwing up
    res = []
    muid_format, muid_type = dataset_topics.first.muid_format, dataset_topics.first.muid_type
    raw_results.first.each_with_index do |council_id, i|
      council = councils.detect{ |c| c.id == council_id }
      res<< BareDatapoint.new(:area => council, :value => raw_results.last[i], :muid_format => muid_format, :muid_type => muid_type)
    end
    res
  end

  def parents
    [dataset]
  end
  
end
