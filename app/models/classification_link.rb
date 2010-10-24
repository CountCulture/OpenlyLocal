class ClassificationLink < ActiveRecord::Base
  belongs_to :classification
  belongs_to :classified, :polymorphic => true
  validates_presence_of :classification_id, :classified_type, :classified_id
end
