class Investigation < ActiveRecord::Base
  Bodies = {'SBE' => 'Standards Body for England',
            'LGO' => "Local Government Ombudsman"}
  validates_presence_of :organisation_name, :standards_body
  before_save :update_blank_description
  
  private
  def update_blank_description
    self.description = DocumentUtilities.precis(case_details) if description.blank?
  end
end
