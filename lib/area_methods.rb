# Various statistical methods shared by ward and council.
# Tests for this are in council_test.rb (with smaller set in ward_test.rb)
module AreaMethods
  SortOrder = %w(in_words graph) # sort order of groupings. Groupings with display_as nil or not in list will come at the end
  
  module ClassMethods
    
  end
  
  module InstanceMethods
    def grouped_datapoints
      sort_order = (SortOrder + [nil]).reverse # make in to a form so that sorting by index will return first place when display_as is nil, or if isn't in list. This will be reversed to last place by reversing sort.
      res = ActiveSupport::OrderedHash.new
      groups = self.datapoints.with_topic_grouping.group_by{ |dp| dp.dataset_topic.dataset_topic_grouping }.to_a #get the datapoints and group by topic_grouping
      dataset_groups = Dataset.in_topic_grouping.collect do |ds|
        dps = ds.calculated_datapoints_for(self)
        [ds.dataset_topic_grouping, dps] if dps
      end # get groupings for datasets -- these are actually BareDatapoints
      groups += dataset_groups.compact
      groups = groups.sort{ |a,b| sort_order.index(b.first.display_as).to_i <=> sort_order.index(a.first.display_as).to_i } # sort into order accoding to given sort order
      groups.each{ |a| res[a.first] = a.last.sort_by{ |e| e.send(a.first.sort_by.blank? ? "short_title" : a.first.sort_by) } } #add to new ordered hash, sorting datapoints by grouping sort order or short_title if no sort_order
      res
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.send :include, InstanceMethods
    receiver.belongs_to :output_area_classification
    receiver.has_many :datapoints, :as => :area
    receiver.has_one :boundary, :as => :area
    receiver.named_scope :restrict_to_oac, lambda { |options| options[:output_area_classification_id] ? 
        { :conditions => {:output_area_classification_id  => options[:output_area_classification_id] } }: 
        { } 
      }
    receiver.delegate :hectares, :to => "boundary", :allow_nil => true
  end

end