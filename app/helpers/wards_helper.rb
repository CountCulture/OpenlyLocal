module WardsHelper

  def ons_statistics_graph(stats_group)
    return if stats_group.blank?
    data = stats_group.values.first.collect{|dp| dp.value.to_f } # google charts library requires numbers, not strings. convert to floats because some numbers will be decimals, not integers
    legend = stats_group.values.first.collect{|dp| dp.title}
    image_tag(Gchart.pie(:data => data, :legend => legend, :size => "300x100"), :class => "chart", :alt => "#{stats_group.keys.first.to_s.titleize} graph")
  end

  def ons_statistics_in_words(stats_group)
    return if stats_group.blank?
    stats_group.values.first.collect do |datapoint|
      case datapoint.muid_type
      when 'Age'
        "#{link_to(datapoint.short_title, datapoint)} #{formatted_datapoint_value(datapoint)}"
      else
        "#{formatted_datapoint_value(datapoint)} #{link_to(datapoint.short_title, datapoint)}"
      end

    end.join(', ')
  end

end
