module AreasHelper
  def crime_stats_graph(comparison_data)
    return if comparison_data.blank?
    data = comparison_data.collect{|period| ["#{period['date']}-01".to_date.to_s(:month_and_year), period['value'].to_f, (period['force_value']&&period['force_value'].to_f) ]}.transpose
    y_max = data[1..-1].flatten.compact.max.ceil
    chart = Gchart.line( :data => data[1..-1],
                         :max_value => y_max,
                         :legend => ['This area', 'Force Average'], 
                         :size => '290x120', 
                         :line_colors => "003366,999999", 
                         :axis_with_labels => 'x,y', 
                         :axis_labels => [data[0].values_at(0,-1), [0,y_max]], 
                         :graph_bg => {:color => 'ffffff,1,ddeeff,0', :type => 'gradient', :angle => 90}, 
                         :custom => 'chdlp=t')
    image_tag(chart, :class => 'chart', :alt => 'Crime Statistics Graph')
  end
end
