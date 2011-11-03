class PlanningApplication < ActiveRecord::Base
  include ScrapedModel::Base
  belongs_to :council
  validates_presence_of :council_id, :uid
  alias_attribute :council_reference, :uid
  serialize :other_attributes
  named_scope :stale, lambda { { :conditions => ["retrieved_at IS NULL OR retrieved_at < ?", 7.days.ago] } }
  
  
  def title
    "Planning Application #{uid}" + (address.blank? ? '' : ", #{address[0..30]}...")
  end
end
