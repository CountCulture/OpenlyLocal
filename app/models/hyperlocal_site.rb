class HyperlocalSite < ActiveRecord::Base
  PossiblePlatforms = %w(Blogger/Blogspot Ning Posterous Wordpress Drupal JournalLocal)
  include TwitterAccountMethods
  attr_protected :approved
  belongs_to :hyperlocal_group
  belongs_to :council
  has_many :feed_entries, :as => :feed_owner, :limit => 5
  validates_presence_of :title, :email, :url
  validates_uniqueness_of :url, :case_sensitive => false
  validates_presence_of :lat, :lng, :distance_covered, :description, :on => :create, :message => "can't be blank"
  # validates_uniqueness_of :title
  # validates_uniqueness_of :url
  validates_inclusion_of :platform, :in => PossiblePlatforms, :allow_blank => true
  validates_inclusion_of :country, :in => AllowedCountries + ['Republic of Ireland']
  named_scope :approved, :conditions => {:approved => true}, :include => [:twitter_account]
  named_scope :independent, lambda { |restriction| restriction ? {:conditions => {:hyperlocal_group_id => nil} } : {} }
  named_scope :country, lambda { |country| country ? { :conditions => {:country => country } } : {} }
  named_scope :region, lambda { |region| region ? { :include => :council, :conditions => { :councils=>{ :region => region } } } : {} }

  acts_as_mappable
  default_scope :order => "title"
  delegate :region, :to => :council, :allow_nil => true
  before_create :set_geom
  after_save :tweet_about_it
  
  def self.find_from_article_url(article_url)
    return unless host = URI.parse(article_url).host rescue nil
    approved.first(:conditions => ['UPPER(url) LIKE ?', "%#{host.upcase}%"])
  end
  
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
  def google_cse_url
    url =~ /\/$/ ? "#{url}*" : "#{url}/*"
  end
  
  def google_map_magnification
    9
  end
  
  def url=(raw_url)
    self[:url] = TitleNormaliser.normalise_url(raw_url)
  end
  
private

  def tweet_about_it
    if approved && !approved_was
      message = (twitter_account_name ? "@#{twitter_account_name}" : title) + " has been added to OpenlyLocal #hyperlocal directory"
      options = {}
      Tweeter.new(message, {:url => "http://openlylocal.com/hyperlocal_sites/#{self.to_param}", :lat => lat, :long => lng}).delay.perform
    end
    true
  end

  def set_geom
    if lat? && lng?
      unless geom?
        self.geom = Point.from_x_y(lng, lat, 4326)
      end
      #unless metres?
      #  self.metres = Point.from_x_y(lng, lat, 27700)
      #end
    end
  end
end
