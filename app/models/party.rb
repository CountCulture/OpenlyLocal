class Party
  attr_reader :name, :colour, :dbpedia_uri
  
  # aliases PARTIES constant to make for easier testing, and also should we change interface in future
  def self.raw_data
    PARTIES
  end
  
  def initialize(raw_name)
    if party_details = self.class.raw_data.detect{ |p| p.first.include?(raw_name) }
      @name = party_details.first.first # assign first element of names array which is the canonical one
      @colour = party_details[1]
      @dbpedia_uri = party_details[2] ? "http://dbpedia.org/resource/#{party_details[2]}" : nil
    else
      @name = raw_name.blank? ? nil : raw_name # set to nil if empty string
    end
  end
  
  # Allows us to test whether it's blank?
  def empty?
    name.blank?
  end
  
  # Override to_s to we can treat as a string in views
  def to_s
    @name.to_s
  end
  
  def ==(comparison_object)
    comparison_object.equal?(self) ||
      (comparison_object.instance_of?(self.class) &&
        comparison_object.name == name)    
  end
end