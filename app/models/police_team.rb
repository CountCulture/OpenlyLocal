class PoliceTeam < ActiveRecord::Base

  belongs_to :police_force
  has_many :police_officers
  validates_presence_of :name, :uid, :police_force_id
  default_scope :order => 'name'
  alias_attribute :title, :name
  
  def extended_title
    "#{title} neighbourhood team (#{police_force.name})"
  end
  
  def update_officers
    return unless response = NpiaUtilities::Client.new(:team_people, :force => police_force.npia_id, :team => uid).response
    existing_officers = police_officers.dup
    officers = [response['person']].flatten.collect do |person|
      if existing_officer = existing_officers.detect{ |o| (o.name == person['name']) && (o.rank == person['rank']) }
        existing_officers -= [existing_officer]
        existing_officer.update_attributes(:biography => person['bio'])
      else
        police_officers.create!(:name => person['name'], :rank => person['rank'], :biography => person['bio'])
      end
    end
    existing_officers.each{|o| o.update_attribute(:active, false)} # ones left in existing officers collection are inactive and should be marked as such
    officers
  end
  
  # Can be removed when resource_methods module mixed in
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
end
