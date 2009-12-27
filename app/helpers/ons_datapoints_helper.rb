module OnsDatapointsHelper
  def formatted_datapoint_value(datapoint)
    return if datapoint.value.blank?
    if datapoint.muid_type == "Pounds Sterling"
      "£#{number_with_delimiter(datapoint.value)}"
    elsif datapoint.value.to_i >= 1000
      number_with_delimiter(datapoint.value)
    else
      datapoint.muid_format ? sprintf(datapoint.muid_format, datapoint.value) : datapoint.value
    end
  end
end
