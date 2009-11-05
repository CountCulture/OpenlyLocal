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
    xml.Require :feature => "setprefs"
    xml.Require :feature => "opensocial-0.9"
    xml.Preload :href    => "http://openlylocal.com/councils/__UP_council__.json"
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
  xml.UserPref :name => "selectedTab",
               :datatype => "hidden"
  
  xml.Content :type => "html" do
    xml.cdata!  render( :partial => "tools/gadget_test_script.html.erb" )
    
  end

end
