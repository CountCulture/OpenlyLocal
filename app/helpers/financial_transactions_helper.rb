module FinancialTransactionsHelper
  # Produces a data of some sort depending on the fuziness of the data, e.g. particular month, or quarte in a year
  def date_with_fuzziness_for(obj)
    case obj.date_fuzziness
    when nil
      obj.date.to_s(:custom_short)
    when 0..3
      "about #{obj.date.to_s(:custom_short)}"
    when 3..29
      obj.date.strftime('%b %Y')
    when 30
      obj.date.strftime("#{Date::ABBR_MONTHNAMES[obj.date.month-1]}-%b %Y")
    else
      obj.date.strftime("#{(1+obj.date.month/3).ordinalize} quarter %Y")
    end
  end
  
  def spend_by_month_graph(spend_data)
    return if spend_data.blank?
    spare_colours = (3..13).collect { |i| "664422#{i.to_s(16).upcase*2}" } # iterate through numbers, turning them in to hex and adding to base colour
    months, data = spend_data.transpose
    data = data.collect(&:to_i)
    column_width = ((240-data.size)/(data.size)).to_i
    max_value = data.max
    rounded_no_above_max = ("%10.1e" % max_value).strip.sub(/(\d\.\d)/){|m|(m.to_f+0.1).to_s}.to_f.to_i
    
    x_axis_labels = [0, currency_for_graph(rounded_no_above_max/2), currency_for_graph(rounded_no_above_max)]
    y_axis_labels = []
    gaps_between_y_labels = 50/column_width + 1
    months.each_with_index{ |d,i| y_axis_labels << (i%gaps_between_y_labels == 0 ? d.to_s(:month_and_year) : nil)}
    image_tag(Gchart.bar( :data => data, 
                          :axis_with_labels => 'x,y',
                          :axis_labels => [ y_axis_labels, x_axis_labels], 
                          :size => "320x200",
                          :max_value => rounded_no_above_max,
                          # :bar_colors => 'BBCCDD',
                          :bar_width_and_spacing => { :spacing => 1, :width =>column_width }
                          ), 
              :class => "chart", :alt => "Spend By Month Chart")
  end
  
  def currency_for_graph(number)
    number < 1000000 ? number_to_currency(number, :precision => 0, :unit => "&pound;") : 
                        "#{number_to_currency(number/1000000.0, :precision => 1, :unit => "&pound;")}m"
  end
end
