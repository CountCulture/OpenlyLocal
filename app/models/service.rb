class Service < ActiveRecord::Base
  belongs_to :council
  belongs_to :ldg_service
  default_scope :order => "title"
  named_scope :matching_term, lambda { |term| { :conditions => ["title LIKE ?", "%#{term}%"] } }
  named_scope :stale, lambda { { :conditions => ["updated_at < ?", 7.days.ago] } }
  validates_presence_of :council_id, :title, :url, :category, :ldg_service_id
  validates_uniqueness_of :ldg_service_id, :scope => :council_id
  
  def self.for_lgsl_id(ids)
    spending_ldg_service_ids = LdgService.find_all_by_lgsl(ids).collect(&:id)
    sds = Service.all(:conditions => {:ldg_service_id => spending_ldg_service_ids}, :include => :council)
  end
  
  def self.refresh_all_urls
    Council.with_stale_services.each do |council|
      refresh_urls_for(council)
    end
  end
  
  def self.refresh_urls_for(council)
    service_pages = council.potential_services.collect do |ldg_service|
      destination_url_info = ldg_service.destination_url(council)
      destination_url_info.blank? ? nil : destination_url_info.merge(:ldg_service => ldg_service) unless destination_url_info.blank?
    end.compact
    
    sp1 = service_pages.group_by{ |p| p[:url] }.to_a
    sp2 = sp1.select{ |g| (g[0]=~/contact/i || g[1].first[:title]=~/contact/i) && g[1].size>1}
    contact_us_pages = sp2.collect{ |g| g[1] }.flatten
    service_pages -= contact_us_pages 
    puts "adding #{service_pages.size} service urls for #{council.name}" unless RAILS_ENV == 'test'
    service_pages.each do |page|
      url, title, ldg_service = page[:url], page[:title], page[:ldg_service]
      existing_service = council.services.find_by_ldg_service_id(page[:ldg_service].id)
      existing_service ? existing_service.update_attributes(:url => url, :title => ldg_service.title, :category => ldg_service.category) : Service.create!(:url => url, :title => ldg_service.title, :category => ldg_service.category, :ldg_service => ldg_service, :council => council)
    end
    puts "About to destroy #{council.services.stale.size} stale services for #{council.name}" unless RAILS_ENV == 'test'
    council.services.stale.each(&:destroy) # get rid of stale pages
  end
  
  def self.spending_data_services_for_councils
    sds = for_lgsl_id(LdgService::SPEND_OVER_500_LGSL)
    councils_with_imported_spending_data = Council.all(:joins => :suppliers, :select => 'councils.id', :group => 'councils.id').collect(&:id) #if don't group by returns a council for each service the council has, with huge memory issues, 
    sds.delete_if{ |service| councils_with_imported_spending_data.include?(service.council_id) }
    sds.sort_by{ |s| s.council.title }
  end
  
end
                           