class Service < ActiveRecord::Base
  belongs_to :council
  belongs_to :ldg_service
  named_scope :matching_term, lambda { |term| { :conditions => ["title LIKE ?", "%#{term}%"] } }
  validates_presence_of :council_id, :title, :url, :category, :ldg_service_id
  
  def self.refresh_urls
    Council.all(:conditions => "ldg_id IS NOT NULL").each do |council|
      council.potential_services.each do |ldg_service|
        url = ldg_service.destination_url(council)
        existing_service = council.services.find_by_ldg_service_id(ldg_service.id)
        existing_service ? existing_service.update_attributes(:url => url, :title => ldg_service.title, :category => ldg_service.category) : Service.create!(:url => url, :title => ldg_service.title, :category => ldg_service.category, :ldg_service => ldg_service, :council => council) unless url.blank?
      end
    end
    Service.delete_all(["updated_at < ?", 1.day.ago])
  end
end                                