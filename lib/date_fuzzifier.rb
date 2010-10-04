module DateFuzzifier
  extend self

  def date_with_fuzziness(date, date_fuzziness=nil)
    case date_fuzziness
    when nil
      date.to_s(:custom_short)
    when 0..3
      "about #{date.to_s(:custom_short)}"
    when 3..29
      date.strftime('%b %Y')
    when 30
      date.strftime("#{Date::ABBR_MONTHNAMES[date.month-1]}-%b %Y")
    else
      date.strftime("#{(1+date.month/3).ordinalize} quarter %Y")
    end
  end
  
end