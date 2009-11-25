class ScrapedObjectResult
  attr_reader :base_object_klass, :id, :title, :changes, :errors, :url, :status
  
  def initialize(obj=nil)
    return unless obj
    obj.attributes.each do |k,v|
      instance_variable_set("@#{k}", v) if respond_to?(k)
    end
    @title ||= obj.title #title may be a facade column and therefore not in attributes
    @changes = truncate_values(obj.changes)
    @errors = obj.errors
    @base_object_klass = obj.class.to_s
    @status = 
      case 
      when obj.new_record? || obj.new_record_before_save?
        "new"
      when obj.changed?
        "changed"
      else
        "unchanged"
      end
    @status += " errors" unless @errors.empty?
  end
  
  # Makes testing possible. Basically was this created from an equivalent AR type object (i.e. one that has same id and class)
  def ==(obj)
    obj.is_a?(ScrapedObjectResult) &&
      base_object_klass == obj.base_object_klass &&
      id == obj.id 
  end
  
  private
  def truncate_values(hsh)
    return if hsh.blank?
    hsh.each do |k,v|
      hsh[k] = ActionController::Base.helpers.truncate(v, :length => 200) if v.is_a?(String)
    end
  end
  
end