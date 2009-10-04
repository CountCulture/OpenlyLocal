xml.instruct!

xml.Module do
  xml.ModulePrefs :title => "UK Council info :: OpenlyLocal",
                  :directory_title => "UK Council info :: OpenlyLocal",
                  :description => "Get info on what your council is doing from OpenlyLocal.com :: making Local Government more transparent",
                  :author => "CountCulture",
                  :author_affiliation => "OpenlyLocal.com",
                  :author_email => "countculture@gmail.com",
                  :height => "250",
                  :scrolling => "true",
                  :singleton => "false",
                  :author_link => "http://OpenlyLocal.com" do
                    
    xml.Require :feature => "settitle"
    xml.Require :feature => "tabs"
  end
  
  xml.UserPref :name => "council",  
               :display_name => "Council", 
               :datatype => "enum",
               :required => "true" do
    @councils.each do |council|
      xml.EnumValue :value => council.id.to_s, 
                    :display_value => council.name             

    end
  end
  
  xml.Content :type => "html" do
    xml.cdata!  render( :partial => "tools/gadget_script.html.erb" )
    
  end

end
