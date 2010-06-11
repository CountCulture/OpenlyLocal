class Supplier < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  has_many :financial_transactions
  validates_presence_of :organisation_id, :organisation_type
  validates_uniqueness_of :uid, :scope => [:organisation_type, :organisation_id], :allow_nil => true
  alias_attribute :title, :name
  
  def validate
    errors.add_to_base('Either a name or uid is required') if name.blank? && uid.blank?
  end
end
