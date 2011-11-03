class AttribObject
  attr_accessor :attrib_name, :parsing_code
  attr_reader :to_param
  
  def initialize(attrib_name=nil, parsing_code=nil)
    @attrib_name = attrib_name
    @parsing_code = parsing_code
  end
  
  
end