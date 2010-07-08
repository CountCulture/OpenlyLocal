class UserSubmissionDetails
  
  def initialize(params={})
    params.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end
  
  # stub method that should be overriden in child classes
  def approve(submission=nil)
  end
  
  def attribute_names
    (self.class.instance_methods-Object.methods).select{ |a| a =~ /=$/ }.collect{ |w| w.sub(/=$/,'') }
  end
  
  def attributes
    attrib_hash = {}
    attribute_names.each{ |a| attrib_hash[a.to_sym] = self.send(a)  }
    attrib_hash
  end
  
  # by default returns false if all attributes are blank, true otherwise. Overwrite in subclasses for different behaviour
  def valid?
    attributes.any?{ |k,v| !v.blank? }
  end
  
end