class Officer < ActiveRecord::Base
  validates_presence_of :last_name, :position, :council_id
  belongs_to :council
  
  def validate
    # can't do if council.chief_executive(true) becuase then council caches old council
    errors.add_to_base("A Chief Executive already exists for this council") if Officer.find_by_council_id_and_position(council_id, "Chief Executive") 
  end
  
  def full_name=(full_name)
    names_hash = NameParser.parse(full_name)
    %w(first_name last_name name_title qualifications).each do |a|
      self.send("#{a}=", names_hash[a.to_sym])
    end
  end
  
  def full_name
    "#{first_name} #{last_name}"
  end  
  
end
