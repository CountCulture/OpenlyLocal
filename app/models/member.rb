#atttributes url, constituency, party

class Member < ActiveRecord::Base
  include ScrapedModel::Base
  include SocialNetworkingUtilities::Base
  validates_presence_of :last_name, :uid, :council_id
  validates_presence_of :url, :unless => :ex_member?
  validates_uniqueness_of :uid, :scope => :council_id # uid is unique id number assigned by council. It's possible that some councils may not assign them (e.g. GLA), but cross that bridge...
  has_many :memberships, :primary_key => :id
  has_many :committees, :through => :memberships do
    def potential_meetings
      reduce([]) do |memo,committee|
        memo += committee.meetings
      end.sort_by do |meeting|
        meeting.date_held.to_datetime
      end
    end

    def forthcoming_meetings
      reduce([]) do |memo,committee|
        memo += committee.meetings.all(:conditions => ['date_held > ?', Time.now])
      end.sort_by do |meeting|
        meeting.date_held.to_datetime
      end
    end
  end

  has_many :candidacies
  has_many :related_articles, :as => :subject
  belongs_to :council
  belongs_to :ward
  allow_access_to :committees, :via => [:uid, :normalised_title]
  allow_access_to :ward, :via => [:uid, :name]
  named_scope :current, :conditions => {:date_left => nil}, :include => [:twitter_account] # we nearly always want these
  named_scope :except_vacancies, :conditions => ['UPPER(last_name) NOT LIKE ? AND UPPER(first_name) NOT LIKE ?', 'VACAN%', 'VACAN%']
  alias_attribute :title, :full_name
  after_create :tweet_about_it

  def potential_meetings
    committees.potential_meetings
  end

  def forthcoming_meetings
    committees.forthcoming_meetings
  end
  
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
  
  def foaf_telephone
    "tel:+44-#{telephone.gsub(/^0/, '').gsub(/\s/, '-')}" unless telephone.blank?
  end
  
  def latest_succesful_candidacy
    candidacies.first(:conditions => "votes IS NOT NULL AND elected = '1'", :include => :poll, :order => 'polls.date_held DESC')
  end
  
  # overrides stub method from TwitterAccountMethods
  def twitter_list_name
    "ukcouncillors"
  end
  
  def mark_as_ex_member
    update_attribute(:date_left, Date.today) if date_left.blank?
  end
  
  def party=(party_name)
    self[:party] = Party.new(party_name).to_s
  end
  
  def party
    Party.new(self[:party])
  end
  
  def status
    vacancy? ? 'vacancy' : (ex_member? ? 'ex_member' : nil)
  end
  
  def vacancy?
    full_name =~ /vacancy|vacant/i
  end
  
  protected
  # overwrites standard orphan_records_callback (defined in ScrapedModel mixin) to mark members as left and notify admin
  def self.orphan_records_callback(recs=nil, options={})
    return if recs.blank? || !options[:save_results] || recs.all?{ |r| r.ex_member? } #skip if no records or doing dry run, or if all records already marked
    recs = recs.select{ |r| !r.ex_member? } #eleminate ex_members
    logger.debug { "**** #{recs.size} orphan Member records: #{recs.inspect}" }
    recs.delete_if{ |r| (r.full_name =~ /vacancy|vacant/i)&&r.destroy}
    recs.each { |r| r.mark_as_ex_member }
    Airbrake.notify(
      :error_class => "OrphanRecords",
      :error_message => "#{recs.size} orphan Member records found for : #{recs.first.council.name}.\n#{recs.inspect}",
      :request => { :params => options }
    )
  end
  
  private
  def tweet_about_it
    if (council.members.count == 1) && (council.committees.count > 0)
      options = council.lat.blank? ? {} : {:lat => council.lat, :long => council.lng}
      message = (council.title.length > 60 ? council.short_name : council.title) + " has been added to OpenlyLocal #localgov #opendata " + (council.twitter_account_name.blank? ? '' : "@#{council.twitter_account_name}")
      Tweeter.new(message, {:url => "http://openlylocal.com/councils/#{council.to_param}"}.merge(options)).delay.perform
    end
    true
  end

end
