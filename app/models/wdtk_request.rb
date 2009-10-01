class WdtkRequest < ActiveRecord::Base
  BASE_URL = "http://www.whatdotheyknow.com"
  belongs_to :council
  validates_presence_of :title, :council_id
  validates_uniqueness_of :url
  default_scope :order => "updated_at DESC"
  
  def self.process
    Council.find(:all, :conditions => "wdtk_name IS NOT NULL").each do |council|
      update_wdtk_info_for(council)
    end
    clean_up
  end
  
  def self.update_wdtk_info_for(council)
    next_page = nil
    begin
      url = next_page || BASE_URL + "/body/#{council.wdtk_name}" #if no next page construct standard WDTK url
      logger.debug { "About to get WDTK info for #{council.name} from #{url}" }
      info = parse(_http_get(url))
      return if info.blank?
      info[:results].collect do |req_hash|
        if existing_record = find_by_url(req_hash[:url])
          existing_record.update_attributes(req_hash)
        else
          WdtkRequest.create!(req_hash.merge(:council => council))
        end
      end
      logger.debug { "Added or updated #{info[:results].size} WDTK requests for #{council.name}" }
      next_page = info[:next_page]
      sleep(3) # give WDTK server time to breath
    end while next_page
  end
  
  protected
  def self._http_get(url)
    return if RAILS_ENV=="test"  # make sure we don't call make calls to external services in test environment. Mock this method to simulate response instead
    open(url)
  end
  
  def self.clean_up
    delete_all(["updated_at < ?", 1.month.ago])
  end
  
  def self.parse(html)
    return if html.blank?
    doc = Hpricot(html)
    requests = doc.search("div.request_listing")
    results = requests.collect do |request_info|
      result_hash = {}
      result_hash[:url] = BASE_URL + request_info.at("a")[:href].strip.sub(/#.+$/,'')
      result_hash[:title] = request_info.at("a").inner_text.strip
      result_hash[:status] = request_info.at(".bottomline strong").inner_text.strip.sub('.', '')
      result_hash[:description] = request_info.at(".desc").inner_text.strip
      result_hash
    end
    next_page = doc.at(".pagination a.next_page")&&(BASE_URL + doc.at(".pagination a.next_page")[:href])
    { :results => results, :next_page => next_page }
  end
end
