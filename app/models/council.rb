# attributes: url wikipedia_url location

class Council < ActiveRecord::Base
  AUTHORITY_TYPES = {
    "London Borough" => "http://en.wikipedia.org/wiki/London_borough",
    "Unitary" => "http://en.wikipedia.org/wiki/Unitary_authority",
    "District" => "http://en.wikipedia.org/wiki/Districts_of_England",
    "County" => "http://en.wikipedia.org/wiki/Non-metropolitan_county",
    "Metropolitan Borough" => "http://en.wikipedia.org/wiki/Metropolitan_borough"
  }

  include PartyBreakdown
  include AreaMethods
  include TwitterAccountMethods
  include SpendingStatUtilities::Base
  include SpendingStatUtilities::Payer
  include SpendingStatUtilities::Payee
  has_many :members, :order => "last_name"
  has_many :committees, :order => "title"
  has_many :memberships, :through => :members
  has_many :scrapers
  has_many :meetings
  has_many :held_meetings, :class_name => "Meeting", :conditions => 'date_held <= \'#{Time.now.to_s(:db)}\''
  has_many :wards, :conditions => {:defunkt => false}, :order => 'wards.name'
  has_many :officers
  has_one  :chief_executive, :class_name => "Officer", :conditions => {:position => "Chief Executive"}
  has_one  :police_authority, :through => :police_force
  has_many :meeting_documents, :through => :meetings, :source => :documents, :select => "documents.id, documents.title, documents.precis, documents.url, documents.document_type, documents.document_owner_type, documents.document_owner_id, documents.created_at, documents.updated_at", :order => "documents.created_at DESC", :include => {:document_owner => :committee}
  has_many :past_meeting_documents, :through => :held_meetings, :source => :documents, :order => "documents.created_at DESC"
  has_many :services
  has_many :dataset_topics, :through => :datapoints
  has_many :polls, :as => :area  
  belongs_to :parent_authority, :class_name => "Council", :foreign_key => "parent_authority_id"
  has_many :child_authorities, :class_name => "Council", :foreign_key => "parent_authority_id", :order => "name"
  has_many :hyperlocal_sites, :conditions => {:approved => true}
  has_many :feed_entries, :as => :feed_owner
  has_many :financial_transactions, :through => :suppliers
  has_many :account_lines, :as => :organisation
  has_many :planning_applications
  belongs_to :portal_system
  belongs_to :police_force
  belongs_to :pension_fund
  validates_presence_of :name
  validates_uniqueness_of :name
  named_scope :parsed, lambda { |options| options ||= {}; options[:include_unparsed] ? 
                      { :select => 'councils.*, COUNT(members.id) AS member_count', 
                        :joins =>'LEFT JOIN members ON members.council_id = councils.id', 
                        :group => "councils.id" } : 
                      { :joins => :members, 
                        :group => "councils.id", 
                        :select => 'councils.*, COUNT(members.id) AS member_count'} }
  default_scope :order => 'councils.name' # fully specify councils.name, in case clashes with another model we're including
  before_save :normalise_title
  delegate :full_name, :to => :chief_executive, :prefix => true, :allow_nil => true
  alias_attribute :title, :name
  alias_method :old_to_xml, :to_xml
  
  NomaliserExceptions = {'lichfield city council' => 'lichfield city',
                         'greater london authority' => 'greater london authority',
                         'kingston[\s-]upon[\s-]hull' => 'hull',
                         'city of london\b' => 'city of london'}
  
  def self.calculated_spending_data
    res = {}
    res[:payee_breakdown] = FinancialTransaction.sum(:value, :joins => :supplier, :group => 'suppliers.payee_type', :conditions => 'suppliers.organisation_type = "Council"')
    res[:total_spend] = res[:payee_breakdown].sum{ |type, val| val }
    res[:company_count] = Company.count(:joins => :supplying_relationships, :conditions => 'suppliers.organisation_type = "Council"')
    res[:transaction_count] = FinancialTransaction.count(:joins => "INNER JOIN suppliers ON financial_transactions.supplier_id = suppliers.id WHERE suppliers.organisation_type = 'Council'")
    res[:supplier_count] = Supplier.count(:conditions => {:organisation_type => 'Council'})
    res[:largest_transactions] = FinancialTransaction.all(:order => 'value DESC', :limit => 20, :joins => "INNER JOIN suppliers ON financial_transactions.supplier_id = suppliers.id WHERE suppliers.organisation_type = 'Council'").collect(&:id)
    res[:largest_companies] = Council.connection.select_rows("SELECT spending_stats.organisation_id FROM `spending_stats` WHERE `spending_stats`.organisation_type = 'Company' ORDER BY spending_stats.total_received_from_councils DESC LIMIT 20").collect{|r| r.first.to_i}
    res[:largest_charities] = Council.connection.select_rows("SELECT spending_stats.organisation_id FROM `spending_stats` WHERE `spending_stats`.organisation_type = 'Charity' ORDER BY spending_stats.total_received_from_councils DESC LIMIT 20").collect{|r| r.first.to_i}
    res
  end
  
  def self.cached_spending_data
    return unless basic_spending_data = super
    basic_spending_data[:largest_transactions] = FinancialTransaction.find(basic_spending_data[:largest_transactions]).sort_by{ |ft| - ft.value }
    basic_spending_data
  end
  
  def self.find_by_params(params={})
    country, region, term, show_open_status, show_1010_status = params.delete(:country), params.delete(:region), params.delete(:term), params.delete(:show_open_status), params.delete(:show_1010_status)
    conditions = term ? ["councils.name LIKE ?", "%#{term}%"] : nil
    conditions ||= {:country => country, :region => region}.delete_if{ |k,v| v.blank?  }
    parsed(:include_unparsed => params.delete(:include_unparsed)||show_open_status||show_1010_status).all({:conditions => conditions, :include => [:twitter_account]}.merge(params))
  end
  
  def self.with_stale_services
    all(:joins => "LEFT JOIN services ON services.council_id=councils.id", :conditions => ["((services.id IS NULL) OR (services.updated_at < ?)) AND (councils.ldg_id IS NOT NULL)", 7.days.ago], :group => "councils.id")
  end
  
  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising council titles
  def self.normalise_title(raw_title)
    unless semi_normed_title = [NomaliserExceptions.detect{|k,v| raw_title =~ Regexp.new(k, true)}].flatten.last
      semi_normed_title = TitleNormaliser.normalise_title(raw_title.gsub(/Metropolitan|\bBorough of|\bBorough|District|City of|City &|City and|City|County of|County|Royal|Council of the|London|Council|Corporation|MBC|LB\b|\([\w\s]+\)/i, ''))
    end
    TitleNormaliser.normalise_title(semi_normed_title)
  end
  
  def self.update_social_networking_info
    report = ""
    total_update_count, total_error_count = 0, 0
    Council.all.each do |council|
      begin
        updating_results = council.update_social_networking_info
        if council.errors[:base]
          report += "========\nProblem updating social network info for #{council.title}: #{council.errors[:base]}\n"
          total_error_count += 1
        end
        total_update_count += updating_results[:updates].to_i
      rescue Exception => e
        report += "========\nException raised getting info for #{council.title}: #{e.inspect}\n"
        total_error_count += 1
      end
    end
    title = "Council Social Networking Info Report: #{total_error_count} errors, #{total_update_count} updates"
    AdminMailer.deliver_admin_alert!( :title => title, :details => report )
  end  
  
  # quick n diirty to return councils without wards (which need to be added). Can prob be removed ultimately
  def self.without_wards
    all(:joins => "LEFT JOIN wards on wards.council_id = councils.id WHERE (wards.id IS NULL)")
  end
  
  # instance methods
  def authority_type_help_url
    AUTHORITY_TYPES[authority_type]
  end
  
  # Returns only active committees if there are active and inactive commmittees, or
  # all committees if there are no active committess (prob because there are no meetings
  # yet in system). Can be made to return all committees by passing true as argument
  def active_committees(include_inactive=nil)
    return committees.with_activity_status if include_inactive
    ac = committees.active
    ac.empty? ? committees : ac
  end 

  # Returns true if council has any active committees, i.e. if council 
  # has any meetings in past year (as meetings must be associated with committees)
  def active_committees?
    meetings.count(:conditions => ["meetings.date_held > ?", 1.year.ago]) > 0
  end
  
  def average_membership_count
    # memberships.average(:group => "members.id")
    memberships.count.to_f/members.current.count
  end
  
  def base_url
    read_attribute(:base_url).blank? ? url : read_attribute(:base_url)
  end
  
  def chief_executive_full_name=(ce_name)
    if ce_name.blank?
      chief_executive&&chief_executive.destroy
    else
      chief_executive ? chief_executive.full_name=(ce_name) : build_chief_executive(:full_name => ce_name)
      chief_executive.save!
    end
  end
  
  # convenience method to allow us to get council for an area, without having to worry whether it is a ward or a council
  def council
    self
  end
  
  # this means we can run party breakdown on council without it having to know about members association
  def members_for_party_breakdown
    members.current
  end
  
  def dbpedia_resource
    wikipedia_url.gsub(/en\.wikipedia.org\/wiki/, "dbpedia.org/resource") unless wikipedia_url.blank?
  end
  
  def fix_my_street_url
    snac_id? ? "http://fixmystreet.com/reports/#{snac_id}" : nil
  end

  def foaf_telephone
    "tel:+44-#{telephone.gsub(/^0/, '').gsub(/\s/, '-')}" unless telephone.blank?
  end
  
  def notify_local_hyperlocal_sites(message, options={})
    # p hyperlocal_sites, self.reload.hyperlocal_sites
    hyperlocal_sites.all(:joins => :twitter_account).each do |site|
      Tweeter.new("@#{site.twitter_account_name} #{message}", options).delay.perform
    end
  end
  
  def openlylocal_url
    "http://#{DefaultDomain}/councils/#{to_param}"
  end
  
  def open_data_licence_name
    Licences[open_data_licence]&&Licences[open_data_licence].first
  end
  
  def open_data_status
    open_data_url? ? (Licences[open_data_licence]&&Licences[open_data_licence].last == 'open' ? 'open_data' : 'semi_open_data') : 'no_open_data'
  end
  
  # A council is considered to be parsed if it has members. Note it is very inefficient to check members 
  # for each council, both on SQL queries and on member (including all members is not a good idea), so 
  # when retruning list of councils we also return member_count attribute and we use this if poss
  def parsed?
    respond_to?(:member_count) ? member_count.to_i > 0 : !members.blank?
  end
  
  def police_force_url
    self[:police_force_url].blank? ? police_force.try(:url) : self[:police_force_url]
  end
    
  def recent_activity
    conditions = ["updated_at > ?", 7.days.ago]
    { :members => members.all(:conditions => conditions),
      :committees => committees.all(:conditions => conditions),
      :meetings => meetings.all(:conditions => conditions),
      :documents => meeting_documents.all(:conditions => ["documents.updated_at > ?", 7.days.ago])}
  end
  
  # returns related councils, i.e. those of same authority type
  def related
    self.class.all(:conditions => {:authority_type => authority_type})
  end
  
  def potential_services(options={})
    return [] if ldg_id.blank?
    authority_level = (authority_type =~ /Metropolitan|London/ ? "Unitary" : authority_type)
    conditions = ["authority_level LIKE ? OR authority_level = 'all'", "%#{authority_level}%"]
    LdgService.all(:conditions => conditions, :order => "lgsl") 
  end
  
  def resource_uri
    "http://#{DefaultDomain}/id/councils/#{id}"
  end
  
  def short_name
    return name if name =~ /City of London|Greater London Authority/
    name.gsub(/&| and|Metropolitan|Borough of|Borough|District|City of|City|County of|County|Royal|Council of the|London|Council|\([\w\s]+\)/, '').squish
  end
  
  def status
    parsed? ? "parsed" : "unparsed"
  end
  
  def to_param
    id ? "#{id}-#{title.gsub(/[^a-z0-9]+/i, '-')}" : nil
  end
  
  def to_xml(options={}, &block)
    old_to_xml({:except => [:base_url, :portal_system_id], :methods => [:openlylocal_url]}.merge(options), &block)
  end
  
  def to_detailed_xml(options={})
    includes = {:members => {:only => [:id, :first_name, :last_name, :party, :url]}, :wards => {}, :twitter_account => {}}
    to_xml({:include => includes}.merge(options)) do |builder|
      builder<<active_committees.to_xml(:skip_instruct => true, :root => "committees", :only => [ :id, :title, :url ], :methods => [:openlylocal_url])
      builder<<meetings.forthcoming.to_xml(:skip_instruct => true, :root => "meetings", :methods => [:title, :formatted_date, :openlylocal_url])
      builder<<recent_activity.to_xml(:skip_instruct => true, :root => "recent-activity")
    end
  end
  
  def update_election_results
    full_results = ElectionResultExtractor.poll_results_for(self)
    if full_results.blank? || full_results[:results].blank?
      logger.info { "No poll results  for #{self.inspect}.\nStatus: #{full_results[:status]}, Errors: #{full_results[:errors]}" }
    else
      full_results[:results].each do |election, polls|
        Poll.from_open_election_data(polls, :council => self)
      end
    end
  end
  
  def update_social_networking_info
    base_result = SocialNetworkingUtilities::Finder.new(url).process
    update_count = 0
    [:twitter_account_name, :feed_url].each do |attrib|
      if send(attrib).blank?
        (update_count +=1) && update_attribute(attrib, base_result[attrib]) unless base_result[attrib].blank?
      else
        errors.add_to_base("new #{attrib} (#{base_result[attrib]}) does not match old #{attrib} (#{send(attrib)})") unless base_result[attrib].blank? || (base_result[attrib].downcase == send(attrib).downcase)
      end
    end
    { :updates => update_count }
  end
  
  private
  def normalise_title
    self.normalised_title = self.class.normalise_title(title)
  end
  
end
