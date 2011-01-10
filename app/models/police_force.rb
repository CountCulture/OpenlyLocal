class PoliceForce < ActiveRecord::Base
  include ResourceMethods
  include SocialNetworkingUtilities::Base
  has_many :councils
  has_many :police_teams
  has_many :crime_areas
  has_many :suppliers, :as => :organisation
  has_many :financial_transactions, :through => :suppliers
  has_one :police_authority
  has_one :force_crime_area, :class_name => "CrimeArea", :foreign_key => "police_force_id", :conditions => {:level => 1}
  validates_presence_of :name, :url
  validates_uniqueness_of :name
  validates_uniqueness_of :url
  default_scope :order => 'name'
  alias_attribute :title, :name
  
  def update_teams
    return unless response = NpiaUtilities::Client.new(:teams, :force => npia_id).response
    existing_teams = police_teams.dup
    teams = [response['team']].flatten.collect do |team|
      if existing_team = existing_teams.detect{ |t| t.uid == team['id'] }
        existing_teams -= [existing_team]
        existing_team.update_attributes(:name => team['name']) unless existing_team.name == team['name']
      else
        police_teams.create!(:name => team['name'], :uid => team['id'])
      end
    end
    existing_teams.each{|t| t.update_attribute(:defunkt, true)} # ones left in existing officers collection are inactive and should be marked as such
    teams    
  end
  
  def openlylocal_url
    "http://#{DefaultDomain}/police_forces/#{to_param}"
  end
  
  def resource_uri
    "http://#{DefaultDomain}/id/police_forces/#{id}"
  end  

end
