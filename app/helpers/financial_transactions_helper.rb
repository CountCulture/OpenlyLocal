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
    spare_colours = (3..13).collect { |i| "664422#{i.to_s(16).upcase*2}" } # iterate through numbers, turning them in to hex and adding to base colour
    months, data = spend_data.transpose
    # colours = parties.collect{ |p| p.colour || spare_colours.shift } # use spare colours if no colour
    image_tag(Gchart.bar(:data => data.collect(&:to_f), :legend => months.collect{ |m| m.to_s(:month_and_year) }, :size => "450x200"), :class => "chart", :alt => "Spend By Month Chart")
    
  end
end
