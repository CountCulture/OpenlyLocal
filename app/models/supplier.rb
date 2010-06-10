class Supplier < ActiveRecord::Base
  belongs_to :organisation, :polymorphic => true
  validates_presence_of :organisation_id, :organisation_type
end
