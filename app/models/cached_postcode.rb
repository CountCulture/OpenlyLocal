class CachedPostcode < ActiveRecord::Base
  belongs_to :output_area
  validates_uniqueness_of :code
  
  # inspired by Stef's code in BCCDIY
  def self.postcode_for(pc_string)
    postcode = find_by_code(pc_string.gsub(/\s/, '').upcase)
    return postcode if postcode
    lookup_url = "http://www.neighbourhood.statistics.gov.uk/dissemination/LeadAreaSearch.do?a=7&r=1&i=1001&m=0&s=1255782024843&enc=1&areaSearchText=#{CGI::escape pc_string}&areaSearchType=15&extendedList=true&searchAreas="
    client = HTTPClient.new
    doc = Hpricot(client.get_content(lookup_url))
    
    if doc.at("title[text()*='Check Browser Settings']")
      follow_link = doc.at('a')[:href]
      doc = Hpricot(client.get_content(follow_link))
    end
    
    oa_code = doc.at("h1 img")[:alt].scan(/Information on ([0-9A-Z]+) /).to_s
    output_area = OutputArea.find_by_oa_code(oa_code)
    create!(:output_area => output_area, :code => pc_string)
  end
  
  def code=(raw_string)
    self[:code] = raw_string.gsub(/\s/, '').upcase
  end
end
