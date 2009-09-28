#atttributes url, constituency, party

class Member < ActiveRecord::Base
  include ScrapedModel::Base
  validates_presence_of :last_name, :url, :uid, :council_id
  validates_uniqueness_of :uid, :scope => :council_id # uid is unique id number assigned by council. It's possible that some councils may not assign them (e.g. GLA), but cross that bridge...
  has_many :memberships, :primary_key => :id
  has_many :committees, :through => :memberships#, :extend => ScrapedModel::UidAssociationExtension
  has_many :potential_meetings, 
           :class_name => 'Meeting',
           :finder_sql => 'SELECT meetings.* from meetings, memberships WHERE 
                           meetings.committee_id=memberships.committee_id 
                           AND memberships.member_id=#{id} ORDER BY meetings.date_held'

  has_many :forthcoming_meetings, 
           :class_name => 'Meeting',
           :finder_sql => 'SELECT meetings.* from meetings, memberships WHERE 
                           meetings.committee_id=memberships.committee_id 
                           AND memberships.member_id=#{id} AND meetings.date_held > \'#{Time.now.to_s(:db)}\' ORDER BY meetings.date_held'

  belongs_to :council
  belongs_to :ward
  allow_access_to :committees, :via => [:uid, :normalised_title]
  named_scope :current, :conditions => "date_left IS NULL"
  alias_attribute :title, :full_name
  after_create :tweet_about_it   
  
  def full_name=(full_name)
    names_hash = NameParser.parse(full_name)
    %w(first_name last_name name_title qualifications).each do |a|
      self.send("#{a}=", names_hash[a.to_sym])
    end
  end
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def ex_member?
    date_left
  end
  
  def party=(party_name)
    self[:party] = party_name.gsub(/party/i, '').sub(/^(The|the)/,'').gsub(/\302\240/,'').strip unless party_name.blank?
  end
  
  def party
    Party.new(self[:party])
  end
  
  private
  def tweet_about_it
    Delayed::Job.enqueue Tweeter.new("#{@council.title.length > 60 ? @council.short_name : @council.title} has been added to OpenlyLocal.com #localdemocracy", :url => "http://openlylocal.com/councils/#{@council.to_param}") if council.members.count == 1
    true
  end
end
