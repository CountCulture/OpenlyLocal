class PoliceOfficer < ActiveRecord::Base
  belongs_to :police_team
  validates_presence_of :name, :police_team_id
  named_scope :active, :conditions => {:active => true}
  
  def biography=(raw_bio)
    return if raw_bio.blank?
    self[:biography] = raw_bio.gsub(/\n+/,"\n").gsub(/\"/,'')
  end
end
