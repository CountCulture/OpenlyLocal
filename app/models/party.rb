class Party
  attr_reader :name, :colour
  
  # aliases PARTIES constant to make for easier testing, and also should we change interface in future
  def self.raw_data
    PARTIES
  end
  
  def initialize(raw_name)
    if party_details = self.class.raw_data.detect{ |p| p.first.include?(raw_name) }
      @name = party_details.first.first # assign first element of names array which is the canonical one
      @colour = party_details.last
    else
      @name = raw_name.blank? ? nil : raw_name # set to nil if empty string
    end
  end
  
  # Override to_s to we can treat as a string in views
  def to_s
    @name.to_s
  end
  
end