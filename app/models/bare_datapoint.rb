class BareDatapoint
  attr_reader :area, :value, :muid_type, :muid_format, :subject
  
  def initialize(args)
    %w(area value subject muid_type muid_format).each do |a|
      instance_variable_set("@#{a}", args[a.to_sym])
    end
  end
  
  def short_title
    subject.short_title
  end
  
end