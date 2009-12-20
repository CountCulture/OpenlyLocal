#atttributes url, constituency, party

class Member < ActiveRecord::Base
  include ScrapedModel::Base
  validates_presence_of :last_name, :url, :uid, :council_id
  validates_uniqueness_of :uid, :scope => :council_id # uid is unique id number assigned by council. It's possible that some councils may not assign them (e.g. GLA), but cross that bridge...
  has_many :memberships, :primary_key => :id
  has_many :committees, :through => :memberships
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
  allow_access_to :ward, :via => [:uid, :name]
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
  
  def foaf_telephone
    "tel:+44-#{telephone.gsub(/^0/, '').gsub(/\s/, '-')}" unless telephone.blank?
  end
  
  def mark_as_ex_member
    update_attribute(:date_left, Date.today) if date_left.blank?
  end
  
  def party=(party_name)
    self[:party] = party_name.gsub(/party/i, '').sub(/^(The|the)/,'').gsub(/\302\240/,'').strip unless party_name.blank?
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
    HoptoadNotifier.notify(
      :error_class => "OrphanRecords",
      :error_message => "#{recs.size} orphan Member records found for : #{recs.first.council.name}.\n#{recs.inspect}",
      :request => { :params => options }
    )
  end
  
  private
  def tweet_about_it
    if council.members.count == 1
      options = {}# council.at.blank? ? {} : {:lat => council.lat, :long => council.long}
      message = (council.title.length > 60 ? council.short_name : council.title) + " has been added to OpenlyLocal #localgov #opendata " +( council.twitter_account.blank? ? '' : "@#{council.twitter_account}")
      Delayed::Job.enqueue(Tweeter.new(message, {:url => "http://openlylocal.com/councils/#{council.to_param}"}.merge(options)))
    end
    true
  end
end
