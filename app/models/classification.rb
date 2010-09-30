class Classification < ActiveRecord::Base
  GROUPINGS = { 'Proclass10.1' => ['Proclass Procurement Classification version 10.1', 'http://websites.uk-plc.net/ProClass/ProClass-Classification-33860.htm'],
                'Proclass8.3' =>  ['Proclass Procurement Classification version 8.3', 'http://websites.uk-plc.net/ProClass/ProClass-Classification-33860.htm']
    
    
  }
  validates_presence_of :title,:grouping
end
