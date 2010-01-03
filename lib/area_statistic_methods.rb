# Various statistical methods shared by ward and council.
# Tests for this are in council_test.rb (with smaller set in ward_test.rb)
module AreaStatisticMethods
  SortOrder = %w(in_words graph) # sort order of groupings. Groupings with display_as nil or not in list will come at the end
  def grouped_datapoints
    sort_order = (SortOrder + [nil]).reverse # make in to a form so that sorting by index will return first place when display_as is nil, or if isn't in list. This will be reversed to last place by reversing sort.
    res = ActiveSupport::OrderedHash.new
    groups = ons_datapoints.with_topic_grouping.group_by{ |dp| dp.ons_dataset_topic.dataset_topic_grouping } #get the datapoints and group by topic_grouping
    groups = groups.to_a.sort{ |a,b| sort_order.index(b.first.display_as).to_i <=> sort_order.index(a.first.display_as).to_i } # sort into order accoding to given sort order
    groups.each{ |a| res[a.first] = a.last.sort_by{ |e| e.send(a.first.sort_by.blank? ? "short_title" : a.first.sort_by) } } #add to new ordered hash, sorting datapoints by grouping sort order or short_title if no sort_order
    res
  end
end