module PlanningApplicationsHelper
  def javascript_obfuscate(text)
    string = ''
    "document.write('#{h(text)}');".each_byte do |c|
      string << sprintf("%%%x", c)
     end
     "<script type=\"#{Mime::JS}\">eval(decodeURIComponent('#{string}'))</script>"
  end
end
