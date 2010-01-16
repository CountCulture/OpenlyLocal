class HyperlocalSite < ActiveRecord::Base
  PossiblePlatforms = %w(Blogger/Blogspot Ning Posterous Wordpress)
  attr_protected :approved
  belongs_to :hyperlocal_group
  belongs_to :council
  validates_presence_of :title, :url
  validates_presence_of :lat, :lng, :on => :create, :message => "can't be blank"
  # validates_uniqueness_of :title
  # validates_uniqueness_of :url
  validates_inclusion_of :platform, :in => PossiblePlatforms, :allow_blank => true
  validates_inclusion_of :country, :in => AllowedCountries
  named_scope :approved, :conditions => {:approved => true}
  acts_as_mappable
  default_scope :order => "title"
  after_save :tweet_about_it
  
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
  private
  def tweet_about_it
    if approved && !approved_was
      message = (twitter_account? ? "@#{twitter_account}" : title) + " has been added to OpenlyLocal #hyperlocal directory"
      options = {}
      Delayed::Job.enqueue(Tweeter.new(message, {:url => "http://openlylocal.com/hyperlocal_sites/#{self.to_param}", :lat => lat, :long => lng}), 1)
    end
    true
  end
end
