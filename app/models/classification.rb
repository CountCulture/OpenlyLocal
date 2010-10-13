class Classification < ActiveRecord::Base
  GROUPINGS = { 'Proclass10.1' => ['Proclass Procurement Classification version 10.1', 'http://websites.uk-plc.net/ProClass/ProClass-Classification-33860.htm'],
                'Proclass8.3' =>  ['Proclass Procurement Classification version 8.3', 'http://websites.uk-plc.net/ProClass/ProClass-Classification-33860.htm'],
                'RORA_200910' => ['CLG RO/RA Local Authority Accounts Return Classification']
    
    
  }
  has_many :children, :class_name => "Classification", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Classification", :foreign_key => "parent_id"
  validates_presence_of :title, :grouping
  
  # overwrite attribute reader to add grouping
  def extended_title
    (self[:extended_title].blank? ? self[:title] : self[:extended_title]) + " (#{grouping_title})"
  end
  
  def grouping_url
    GROUPINGS[grouping]&&GROUPINGS[grouping][1]
  end
  
  def grouping_title
    GROUPINGS[grouping]&&GROUPINGS[grouping][0]
  end
end
