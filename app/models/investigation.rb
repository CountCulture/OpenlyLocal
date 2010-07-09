class Investigation < ActiveRecord::Base
  Bodies = {'SBO' => 'Standards Body for England',
            'LGO' => "Local Government Ombudsman"}
  validates_presence_of :organisation_name, :standards_body
  
end
