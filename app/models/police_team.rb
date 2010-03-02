class PoliceTeam < ActiveRecord::Base

  belongs_to :police_force
  validates_presence_of :name, :uid, :police_force_id
  alias_attribute :title, :name
  
  # Can be removed when resource_methods module mixed in
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
end
