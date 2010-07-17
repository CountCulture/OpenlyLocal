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
end
