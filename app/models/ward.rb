class Ward < ActiveRecord::Base
  include ScrapedModel::Base
  belongs_to :council
  has_many :members
  has_many :committees
  has_many :meetings, :through => :committees
  allow_access_to :members, :via => :uid
  allow_access_to :committees, :via => [:uid, :normalised_title]
  validates_presence_of :name, :council_id
  validates_uniqueness_of :name, :scope => :council_id
  alias_attribute :title, :name

  # This code inspire by Stef's code for BCCDIY'
  # def self.find_by_postcode(pcode)
  #   lookup_url = "http://www.neighbourhood.statistics.gov.uk/dissemination/LeadAreaSearch.do?a=7&r=1&i=1001&m=0&s=1255767609198&enc=1&areaSearchText=#{CGI::escape postcode }&areaSearchType=15&extendedList=true&searchAreas=
  # 
  #   result = ''
  #   doc = Nokogiri::HTML(open(lookup_url))
  # 
  #   logger.info doc
  # 
  #   title = doc.at('title').inner_html
  # 
  #   if title == "Check Browser Settings"
  #     follow_link = doc.css('a').first[:href]
  #     doc = Nokogiri::HTML(open(follow_link))
  #     logger.info doc        
  #   end
  # 
  #   result_title = doc.css('h1').first.inner_html
  #   result = nil
  #   results = result_title.match(/Area: (.*?) \(Ward\)/)
  #   unless results.blank?
  #     result = results[1]
  #   end
  # 
  #   unless result.blank?
  #     #write the results to the lookup cache
  #     
  #     the_ward = Ward.find_by_permalink(result.parameterize)
  #     
  #     p = PostcodeToWard.new(:postcode=>postcode, :ward=>the_ward)
  #     p.save
  #     
  #     return the_ward
  #   else
  #     return nil
  #   end
  # end
  
  # override standard matches_params from ScrapedModel to match against name if uid is blank
  def matches_params(params={})
    self[:name]==clean_name(params[:name]) || (!params[:uid].blank? && super )
  end

  def name=(raw_name)
    self[:name] = clean_name(raw_name)
  end
  
  private
  def clean_name(raw_name)
    raw_name.blank? ? raw_name : raw_name.sub(/ward\s*$/i, '').strip
  end
end
