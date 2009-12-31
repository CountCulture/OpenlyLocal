# Various statistical methods shared by ward and council
module AreaStatisticMethods
  
  def grouped_datapoints
    res = ActiveSupport::OrderedHash.new
    ons_datapoints.with_topic_grouping.group_by{ |dp| dp.ons_dataset_topic.dataset_topic_grouping }.each{ |k,v| res[k] = v.sort_by{ |e| e.send(k.sort_by || "short_title") } }
    res
  end
end