class OnsDatasetFamily < ActiveRecord::Base
  has_and_belongs_to_many :ons_subjects
  has_many :ons_datasets
  has_many :ons_dataset_topics
  has_many :ons_datapoints, :through => :ons_dataset_topics
  belongs_to :statistical_dataset
  validates_presence_of :title
  validates_presence_of :source_type
  validates_presence_of :statistical_dataset_id

  def calculated_datapoints_for_councils
    res = ActiveSupport::OrderedHash.new
    raw_results = ons_datapoints.sum(:value, :group => :area_id, :conditions => {:area_type => 'Council'}, :order => "sum_value DESC").to_a.transpose #for some reason we can't group by polymorphic belongs_to
    councils = Council.find(raw_results.first) # .. so we have to go through hoops if we want to return councils as keys to values, rather than council_ids. B fetching councils gives us default order which we have to blow out
    # There's also the the problem that default_scope on councils returns in named order, not order we asked for them in, and something funny going on with OrderedHash returned from
    # sum, which means order is screwing up
    raw_results.first.each_with_index do |council_id, i|
      council = councils.detect{ |c| c.id == council_id }
      res[council] = raw_results.last[i]
    end
    res
  end

  def parents
    [statistical_dataset]
  end
  
end
