class StatisticalDataset < ActiveRecord::Base
  has_many :ons_dataset_families, :dependent => :destroy
  has_many :ons_dataset_topics, :through => :ons_dataset_families
  validates_presence_of :title, :originator
  validates_uniqueness_of :title

  # Returns Array of Datapoints (strictly BareDatapoints, which are sort of composite 
  # datapoints created when there isn't a real datapoint we can use), each representing 
  # the aggregated value of all datapoints for the whole statistical dataset, grouped 
  # by councils.
  # See also OnsDatasetFamily#calculated_datapoints_for_councils
  def calculated_datapoints_for_councils
    return if ons_dataset_families.any?{ |t| t.calculation_method.blank? }
    raw_results = OnsDatapoint.sum( :value, 
                                    :group => :area_id, 
                                    :conditions => { :area_type => 'Council', :ons_dataset_topic_id => ons_dataset_topics.collect(&:id)}, 
                                    :order => "sum_value DESC").to_a
    return if raw_results.blank?
    raw_results = raw_results.select{ |r| r.last > 0.0 }.transpose
    councils = Council.find(raw_results.first) # .. so we have to go through hoops if we want to return councils as keys to values, rather than council_ids. 
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

  # Returns Array of Datapoints (strictly BareDatapoints, which are sort of composite 
  # datapoints created when there isn't a real datapoint we can use), each representing 
  # the aggregated value of all datapoints for each child dataset family for a given council.
  def calculated_datapoints_for(council)
    return if ons_dataset_families.any?{ |t| t.calculation_method.blank? }
    raw_results = council.ons_datapoints.in_statistical_dataset(self).sum(:value, :group => "ons_dataset_topics.ons_dataset_family_id", :order => "sum_value DESC").to_a
    return if raw_results.blank?
    raw_results = raw_results.transpose
    dataset_families = OnsDatasetFamily.find(raw_results.first) # .. so we have to go through hoops if we want to return ons_dataset_families as keys to values, rather than ons_dataset_families_ids. 
    res = []
    raw_results.first.each_with_index do |dataset_family_id, i|
      dataset_family = dataset_families.detect{ |f| f.id == dataset_family_id.to_i } # NB because we are grouping by SQL (see above) id is not cast into integer
      muid_format, muid_type = dataset_family.ons_dataset_topics.first.muid_format, dataset_family.ons_dataset_topics.first.muid_type
      res<< BareDatapoint.new(:ons_dataset_family => dataset_family, :value => raw_results.last[i], :muid_format => muid_format, :muid_type => muid_type)
    end
    res
  end
end
