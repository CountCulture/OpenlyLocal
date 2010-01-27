xml.instruct!
xml.comment! "Specification file for Google Custom Search Engine for UK Hyperlocal Sites, from OpenlyLocal, http://openlylocal.com"
  xml.GoogleCustomizations do
    
    xml.CustomSearchEngine do
      xml.Title         "OpenlyLocal UK Hyperlocal search engine, powered by Google"
      xml.Description   "Google Custom Search Engine searching UK Hyperlocal News and Community sites appearing on the OpenlyLocal UK Hyperlocal Directory"
      xml.Context do
        xml.BackgroundLabels do
          xml.Label(:name => @cse_label, :mode => "FILTER")
        end
      end
      # xml.LookAndFeel(:nonprofit => "false") do
      #   xml.Colors(:url => "#005689", :background => "#FFFFFF", :border => "#CCCCCC", :title => "#a80e0e", :text => "#0d0d0d", :visited => "#a6d1e2", :light => "#515151")
      # end
    end
    xml.Annotations do
      @hyperlocal_sites.each do |site|
        xml.Annotation(:about => site.google_cse_url) do
          xml.Label(:name => @cse_label)
        end
      end
    end
    
  end
