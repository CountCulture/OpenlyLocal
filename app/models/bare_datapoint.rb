class BareDatapoint
  attr_reader :area, :value, :muid_type, :muid_format
  
  def initialize(args)
    @area = args[:area]
    @value = args[:value]
    @muid_type = args[:muid_type]
    @muid_format = args[:muid_format]
  end
  
end