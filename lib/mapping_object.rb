class MappingObject
  attr_accessor :attrib_name, :column_name
  attr_reader :to_param
  
  def initialize(attrib_name=nil, column_name=nil)
    @attrib_name = attrib_name
    @column_name = column_name
  end  
  
end