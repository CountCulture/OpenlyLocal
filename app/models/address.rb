class Address < ActiveRecord::Base
  belongs_to :addressee, :polymorphic => true
  validates_presence_of :addressee_type, :addressee_id
  UKPostcodeRegex = /[A-Z]{1,2}[0-9R][0-9A-Z]? ?[0-9][A-Z]{2}/


  def in_full
    [street_address, locality, postal_code].select{|a| !a.blank?}.join(', ')
  end
  
  def in_full=(raw_addr)
    raw_address = raw_addr.dup
    self.postal_code = raw_address.slice!(UKPostcodeRegex)
    split_address = raw_address.sub(/^(\d+),/, '\1').split(/,\s*|,?[\r\n]+/).delete_if(&:blank?)
    self.locality = split_address.pop.strip if split_address.size > 1
    self.street_address = split_address.join(', ')
  end
end
