class Candidacy < ActiveRecord::Base
  set_table_name 'candidates'
  include AddressUtilities::Base
  belongs_to :poll
  belongs_to :political_party
  belongs_to :member
  validates_presence_of :poll_id, :last_name
  delegate :area, :to => :poll
  default_scope :order => 'last_name'
  
  def full_name
    first_name.blank? ? last_name : "#{first_name} #{last_name}"
  end
  
  def party_name
    political_party ? political_party.name : party||'Independent'
  end
  
  def status
    elected ? 'elected' : nil
  end
end
