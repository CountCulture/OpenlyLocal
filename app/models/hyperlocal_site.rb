class HyperlocalSite < ActiveRecord::Base
  PossiblePlatforms = %w(Ning Wordpress Blogger/Blogspot)
  attr_protected :approved
  belongs_to :hyperlocal_group
  belongs_to :council
  validates_presence_of :title, :url
  validates_presence_of :lat, :lng, :distance, :on => :create, :message => "can't be blank"
  validates_uniqueness_of :title
  validates_uniqueness_of :url
  validates_inclusion_of :platform, :in => PossiblePlatforms, :allow_blank => true
  validates_inclusion_of :country, :in => AllowedCountries
  named_scope :approved, :conditions => {:approved => true}
  default_scope :order => "title"
end
