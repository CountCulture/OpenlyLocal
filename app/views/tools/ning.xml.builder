xml.instruct!

xml.Module "xmlns:ning" => "http://developer.ning.com/opensocial/" do
  xml.ModulePrefs :title => "UK Council info :: OpenlyLocal",
                  :directory_title => "UK Council info :: OpenlyLocal",
                  :description => "Information about your UK local authority from OpenlyLocal.com :: making Local Government more transparent. Lists forthcoming meetings, committees, council members etc",
                  :thumbnail => "http:/openlylocal.com/images/openlylocal_logo_120x60.png",
                  :author => "CountCulture",
                  :author_affiliation => "OpenlyLocal.com",
                  :author_email => "countculture@gmail.com",
                  :author_link => "http://OpenlyLocal.com" do
    xml.tag! "ning:screenshot", "http://openlylocal.com/images/ning_screenshot_canvas.png", :view => "canvas"
                    
    xml.Require :feature => "opensocial-0.8"
    xml.Require :feature => "dynamic-height"
    xml.Require :feature => "setprefs"
    xml.Require :feature => "views"
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
  end
  
end
