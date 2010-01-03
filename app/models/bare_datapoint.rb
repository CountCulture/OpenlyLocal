class BareDatapoint
  attr_reader :area, :value, :muid_type, :muid_format, :ons_dataset_topic, :ons_dataset_family
  
  def initialize(args)
    %w(area value ons_dataset_topic ons_dataset_family muid_type muid_format).each do |a|
      instance_variable_set("@#{a}", args[a.to_sym])
    end
  end
  
end