class BareDatapoint
  attr_reader :area, :value, :muid_type, :muid_format, :dataset_topic, :dataset_family
  
  def initialize(args)
    %w(area value dataset_topic dataset_family muid_type muid_format).each do |a|
      instance_variable_set("@#{a}", args[a.to_sym])
    end
  end
  
end