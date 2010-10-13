class AccountLine < ActiveRecord::Base
  belongs_to :classification
  belongs_to :organisation, :polymorphic => true
  validates_presence_of :organisation_type, :organisation_id, :classification_id, :period
end
