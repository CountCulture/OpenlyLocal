class Investigation < ActiveRecord::Base
  Bodies = {'SBE' => 'Standards Body for England',
            'LGO' => "Local Government Ombudsman"}
  # has_many :organisations, :through => :investigables
  # has_many :report_subjects, :through => :investiga
  has_many :investigation_subject_connections
  has_many :member_subjects, :through => :investigation_subject_connections, :source => :subject, :source_type => 'Member'
  belongs_to :related_organisation, :polymorphic => true
  validates_presence_of :standards_body
  before_save :update_blank_description
  
  def standards_body_name
    Bodies[self[:standards_body]]
  end
  
  def title
    "Report by #{standards_body_name}, #{self[:title]}"
  end
  
  private
  def update_blank_description
    self.description = DocumentUtilities.precis(case_details) if description.blank?
  end
end
