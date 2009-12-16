module WardsHelper

  def ons_statistics_graph(stats_group)
    return if stats_group.blank?
    data = stats_group.values.first.collect{|dp| dp.value.to_f}
    legend = stats_group.values.first.collect{|dp| dp.title}
    image_tag(Gchart.pie(:data => data, :legend => legend, :size => "300x100"), :class => "chart", :alt => "#{stats_group.keys.first.to_s.titleize} graph")
  end
end
