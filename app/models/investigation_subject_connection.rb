class InvestigationSubjectConnection < ActiveRecord::Base
  belongs_to :investigation
  belongs_to :subject, :polymorphic => true
  validates_presence_of :subject_id, :subject_type, :investigation_id
end
