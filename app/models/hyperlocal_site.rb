class HyperlocalSite < ActiveRecord::Base
  PossiblePlatforms = %w(Ning Wordpress Blogger)
  belongs_to :hyperlocal_group
  validates_presence_of :title, :url
  validates_uniqueness_of :title
  validates_uniqueness_of :url
  validates_inclusion_of :platform, :in => PossiblePlatforms, :allow_blank => true
end
