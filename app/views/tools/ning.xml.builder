xml.instruct!

xml.Module "xmlns:ning" => "http://developer.ning.com/opensocial/" do
  xml.ModulePrefs :title => "Council info :: OpenlyLocal",
                  :directory_title => "UK Council info :: OpenlyLocal",
                  :description => "Get info on what your council is doing from OpenlyLocal.com :: making Local Government more transparent",
                  :author => "CountCulture",
                  :author_affiliation => "OpenlyLocal.com",
                  :author_email => "countculture@gmail.com",
                  :author_link => "http://OpenlyLocal.com" do
                    
    xml.Require :feature => "opensocial-0.8"
    xml.Require :feature => "dynamic-height"
    xml.Require :feature => "setprefs"
    xml.Preload :href    => "http://openlylocal.com/councils/2.json"

  end
  
  # xml.Content :type => "html" do
  #   xml.cdata!  render( :partial => "tools/ning_script.html.erb" )
  #   
  # end
  
  # xml.Content :type => "html", :view => "ning.main" do
  #   xml.cdata!  "<p>Hello, ning.main view!</p>"
  # end
  
  # xml.Content :type => "html", :view => "canvas,profile" do
  #   xml.cdata!  "<p>Hello, Canvas, Profile View!</p> "
  #   # xml.cdata!  render( :partial => "tools/ning_script.html.erb" )
  # end
  
  # xml.Content :type => "html", :view => "profile" do
  #   # xml.cdata!  render( :partial => "tools/ning_script.html.erb" )
  #   xml.cdata!  "<p>Hello, Profile View!</p> "
  # end
  
  xml.Content :type => "html", :view => "canvas" do
    xml.cdata!  render( :partial => "tools/ning_script.html.erb" )
    # xml.cdata!  "<p>Hello, Canvas View!</p> "
  end
  
end
