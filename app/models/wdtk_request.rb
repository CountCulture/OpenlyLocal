class WdtkRequest < ActiveRecord::Base
  BASE_URL = "http://www.whatdotheyknow.com"
  belongs_to :organisation, :polymorphic => true
  belongs_to :related_object, :polymorphic => true
  validates_presence_of :organisation_type, :organisation_id, :request_name#, :uid
  validates_uniqueness_of :request_name
  named_scope :stale, lambda { { :conditions => ["updated_at < ?", 24.hours.ago] } }
  named_scope :problematic, { :conditions => { :problematic => true } }
  default_scope :order => "updated_at DESC"
  
  def self.process
    fetch_all_with_tags('openlylocal')
    stale.each do |req|
      req.update_from_website
    end
  end
  
  def self.fetch_all_with_tags(*tags)
    return unless response = _http_get("http://www.whatdotheyknow.com/feed/search/tag:#{tags.join('%20AND%20tag:')}.json") 
    requests = JSON.parse(response).group_by{|r| r['info_request']}
    requests.collect do |request_name, request_detail_items|
      latest_reponse = request_detail_items.sort{ |a,b| a['created_at'] <=> b['created_at'] }.detect{|r| r['calculated_state']}
      org = Council.find_by_wdtk_name(request_detail_items.first['public_body'])||Entity.find_by_wdtk_name(request_detail_items.first['public_body'])
      # p latest_reponse
      # p request_detail_items.first['public_body'],org
      req = find_or_initialize_by_request_name(:request_name => request_name)
      req.update_attributes(:organisation => org, :title => request_detail_items.first['title'], :status => latest_reponse['calculated_state'] )
    end
    # p requests
  end
  
  def update_from_website
    details = JSON.parse(_http_get("#{url}.json")) rescue nil
    return unless details
    tags = details['tags']
    # if tags.assoc.i
    if tags.transpose.first.include?('openlylocal') && obj_tag = tags.detect{|tag_pair| !tag_pair.first.match(/openlylocal|url/) }
      related_object = obj_tag.first.classify.constantize.find_by_id(obj_tag.last)
    end
    update_attributes(:title => details['title'], :status => details['described_state'], :related_object => related_object)
  end
  
  def url
    "http://www.whatdotheyknow.com/request/#{request_name}"
  end
  
  protected
  def self._http_get(url)
    return if RAILS_ENV=="test"  # make sure we don't call make calls to external services in test environment. Mock this method to simulate response instead
    open(url).read
  end
  
  def _http_get(url)
    self.class.send(:_http_get, url)
  end
  
  # def self.clean_up
  #   delete_all(["updated_at < ?", 1.month.ago])
  # end
  # 
  # def self.parse(html)
  #   return if html.blank?
  #   doc = Hpricot(html)
  #   requests = doc.search("div.request_listing")
  #   results = requests.collect do |request_info|
  #     result_hash = {}
  #     result_hash[:url] = BASE_URL + request_info.at("a")[:href].strip.sub(/#.+$/,'')
  #     result_hash[:title] = request_info.at("a").inner_text.strip
  #     result_hash[:status] = request_info.at(".bottomline strong").inner_text.strip.sub('.', '')
  #     result_hash[:description] = request_info.at(".desc").inner_text.strip
  #     result_hash
  #   end
  #   next_page = doc.at(".pagination a.next_page")&&(BASE_URL + doc.at(".pagination a.next_page")[:href])
  #   { :results => results, :next_page => next_page }
  # end
  # 
end
