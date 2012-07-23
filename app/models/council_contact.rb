class CouncilContact < ActiveRecord::Base
  belongs_to :council
  attr_protected :approved
  named_scope :approved, :conditions => "approved IS NOT NULL"
  named_scope :unapproved, :conditions => {:approved => nil}
  validates_presence_of :council_id, :email, :name, :position
    
  def approve
    update_attribute(:approved, Time.now)
  end
end
